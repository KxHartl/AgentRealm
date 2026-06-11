"""
FSB Seminar Compiler.
Parses a Markdown seminar file, extracts YAML metadata, maps sections,
converts Markdown to LaTeX via Pandoc, and compiles the final LaTeX PDF.
"""

import os
import re
import sys
import subprocess
import shutil

def parse_markdown(md_path: str):
    with open(md_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Extract YAML front matter
    yaml_meta = {}
    yaml_match = re.match(r"^---\s*\n(.*?)\n---\s*\n", content, re.DOTALL)
    body = content
    if yaml_match:
        yaml_block = yaml_match.group(1)
        body = content[yaml_match.end():]
        for line in yaml_block.split("\n"):
            if ":" in line:
                k, v = line.split(":", 1)
                yaml_meta[k.strip().lower()] = v.strip().strip('"').strip("'")

    # Split body into sections
    sections = {
        "uvod": "",
        "pogl2": "",
        "zakljucak": "",
        "literatura": "",
        "prilozi": ""
    }

    # Heuristic split based on headings
    # e.g., # Uvod, # Zaključak, # Literatura, # Prilozi
    parts = re.split(r"^(#+ .*?)$", body, flags=re.MULTILINE)
    
    current_section = None
    for part in parts:
        if part.startswith("#"):
            heading = part.lower()
            if "uvod" in heading:
                current_section = "uvod"
            elif "zaključ" in heading or "zakljuc" in heading:
                current_section = "zakljucak"
            elif "literatur" in heading:
                current_section = "literatura"
            elif "prilog" in heading:
                current_section = "prilozi"
            else:
                current_section = "pogl2"
        else:
            if current_section:
                sections[current_section] += part + "\n"
            else:
                # Content before any heading goes to uvod
                sections["uvod"] += part + "\n"

    return yaml_meta, sections

def md_to_tex(md_text: str) -> str:
    if not md_text.strip():
        return ""
    try:
        # Run pandoc to convert MD fragment to LaTeX fragment
        process = subprocess.Popen(
            ["pandoc", "-f", "markdown", "-t", "latex"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8"
        )
        stdout, stderr = process.communicate(input=md_text)
        if process.returncode == 0:
            return stdout
    except Exception as e:
        print(f"[Compiler] Pandoc fragment conversion failed: {e}")
    return md_text

def compile_seminar(md_path: str, template_path: str, output_pdf_path: str):
    print(f"[Compiler] Processing {md_path}...")
    yaml_meta, sections = parse_markdown(md_path)

    # Read LaTeX template
    with open(template_path, "r", encoding="utf-8") as f:
        template = f.read()

    # Convert sections to LaTeX
    uvod_tex = md_to_tex(sections["uvod"])
    pogl2_tex = md_to_tex(sections["pogl2"])
    zakljucak_tex = md_to_tex(sections["zakljucak"])
    
    # Process bibliography items specifically if present
    lit_text = sections["literatura"].strip()
    lit_tex = ""
    if lit_text:
        # Convert bibliography lines to \bibitem items
        for line in lit_text.split("\n"):
            line = line.strip()
            if line.startswith("-") or line.startswith("*") or re.match(r"^\d+\.", line):
                item_content = re.sub(r"^[-*\d\.]+\s*", "", line)
                # Generate a safe cite key
                key = re.sub(r"\W+", "", item_content[:15]).lower()
                lit_tex += f"\\bibitem{{{key}}} {item_content}\n"
            elif line:
                lit_tex += f"{line}\n"
    else:
        lit_tex = "\\bibitem{placeholder} Placeholder reference."

    prilozi_tex = md_to_tex(sections["prilozi"])

    # Meta replacements
    meta_mappings = {
        "{{IME_I_PREZIME}}": yaml_meta.get("author", "Ime Prezime"),
        "{{KOLEGIJ}}": yaml_meta.get("course", "Kolegij"),
        "{{PROFESOR}}": yaml_meta.get("professor", "Profesor"),
        "{{GODINA}}": yaml_meta.get("year", "2026"),
        "{{UVOD}}": uvod_tex,
        "{{POGLAVLJE_2}}": pogl2_tex,
        "{{ZAKLJUCAK}}": zakljucak_tex,
        "{{LITERATURA}}": lit_tex,
        "{{PRILOZI}}": prilozi_tex
    }

    populated_tex = template
    for placeholder, val in meta_mappings.items():
        populated_tex = populated_tex.replace(placeholder, val)

    # Write populated LaTeX file
    build_dir = "docs/build_temp"
    os.makedirs(build_dir, exist_ok=True)
    temp_tex_path = os.path.join(build_dir, "seminar_compiled.tex")
    
    with open(temp_tex_path, "w", encoding="utf-8") as f:
        f.write(populated_tex)

    print("[Compiler] Running pdflatex on generated LaTeX...")
    try:
        # Run pdflatex (or latexmk)
        subprocess.run(
            ["pdflatex", "-interaction=nonstopmode", "-output-directory", build_dir, temp_tex_path],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=True
        )
        
        generated_pdf = os.path.join(build_dir, "seminar_compiled.pdf")
        if os.path.exists(generated_pdf):
            shutil.copy(generated_pdf, output_pdf_path)
            print(f"✅ Success: {output_pdf_path} compiled successfully!")
        else:
            print("❌ Failed to compile PDF: output file not found.")
    except Exception as e:
        print(f"❌ Failed to run pdflatex: {e}")
    finally:
        # Cleanup temp files
        if os.path.exists(build_dir):
            shutil.rmtree(build_dir)

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: python compile_seminar.py <md_path> <template_path> <output_pdf_path>")
        sys.exit(1)
    compile_seminar(sys.argv[1], sys.argv[2], sys.argv[3])
