#!/usr/bin/env bash
# Unified Documentation Build Script

clean=false
if [[ "${1:-}" == "--clean" ]]; then
  clean=true
fi

root_dir="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$root_dir"

echo "--- 📚 Building Documentation ---"

dist_dir="${root_dir}/dist"
mkdir -p "$dist_dir"

# 1. Build LaTeX documents
find docs -name "*.tex" -not -path "*/templates/*" | while read -r file; do
  echo "[LaTeX] Building $(basename "$file")..."
  out_dir="$(dirname "$file")/build"
  mkdir -p "$out_dir"
  
  latexmk -pdf -interaction=nonstopmode -shell-escape -outdir="$out_dir" "$file"
  
  if [[ $? -eq 0 ]]; then
    pdf_name="$(basename "$file" .tex).pdf"
    if [[ -f "${out_dir}/${pdf_name}" ]]; then
      cp "${out_dir}/${pdf_name}" "${dist_dir}/"
      echo "✅ Success: $pdf_name moved to dist/"
    fi
  else
    echo "❌ Failed to build $file"
  fi
done

# 2. Build Markdown documents with Pandoc
find docs -name "*.md" -not -path "*/templates/*" -not -name "README.md" | while read -r file; do
  echo "[Pandoc] Converting $(basename "$file") to PDF..."
  pdf_name="$(basename "$file" .md).pdf"
  output_path="${dist_dir}/${pdf_name}"

  seminar_template="${root_dir}/.ai/templates/fsb-seminar/latex/seminar.tex"
  compiler_script="${root_dir}/.ai/scripts/helpers/compile_seminar.py"

  if [[ "$file" == *seminar* ]] && [[ -f "$seminar_template" ]] && [[ -f "$compiler_script" ]]; then
    echo "FSB Seminar detected! Utilizing Auto-LaTeX compiler with templates..."
    python3 "$compiler_script" "$file" "$seminar_template" "$output_path"
  else
    pandoc "$file" -o "$output_path" --pdf-engine=pdflatex
  fi

  if [[ $? -eq 0 ]] || [[ -f "$output_path" ]]; then
    echo "✅ Success: $pdf_name generated in dist/"
  else
    echo "❌ Failed to convert $file"
  fi
done

if [[ "$clean" == true ]]; then
  echo "Cleaning up build directories..."
  find docs -type d -name "build" -exec rm -rf {} +
fi

echo "--- ✨ Build Finished ---"
