# Academic Document Templates — Overview

This directory contains three standardized academic document templates maintained for use at the Faculty of Mechanical Engineering and Naval Architecture (FSB), University of Zagreb.

## Templates

| Template | Path | Format | Purpose |
|----------|------|--------|---------|
| **Thesis** (Diplomski rad) | `fsb-thesis/` | 12pt, single-column, A4 | Final thesis / diplomski rad |
| **Seminar** | `fsb-seminar/` | 12pt, single-column, A4 | Course seminar papers |
| **Paper** | `kx-paper/` | 10pt, two-column, A4 | Scientific/conference papers |

## Template Contents
Each template directory contains:
```
template-name/
├── latex/          # LaTeX template (.tex)
├── word/           # Word template (.docx) + reference PDF
├── demo/           # Compiled demo PDFs
├── instructions.md # AI agent instructions for document generation
└── structure.md    # Document structure skeleton
```

## Visual Identity (Shared)
All three templates share a coherent visual identity:
- **Font:** Times New Roman (`mathptmx` LaTeX package)
- **Heading hierarchy:**
  - Section: Bold UPPERCASE (14pt thesis/seminar, 10pt paper)
  - Subsection: Bold
  - Subsubsection: Bold Italic
  - Paragraph: Italic (thesis/seminar only)
- **Figure/Table captions:** 11pt Bold, period separator
- **Figure/Table/Equation numbering:** By chapter (e.g., Slika 2.1)
- **Headers/Footers:** Italic, with student name and document type

## LaTeX Requirements
All required LaTeX packages are listed in `latex-requirements.txt`.

### Check & Install Packages
```powershell
# Dry run (check only):
.\.ai\scripts\helpers\check-latex-packages.ps1 -DryRun

# Check and auto-install missing:
.\.ai\scripts\helpers\check-latex-packages.ps1
```

## Compiling Demos
```bash
cd ..ai/templates/fsb-thesis/demo && pdflatex -interaction=nonstopmode demo_final.tex && pdflatex -interaction=nonstopmode demo_final.tex
cd ..ai/templates/fsb-seminar/demo && pdflatex -interaction=nonstopmode demo_final.tex && pdflatex -interaction=nonstopmode demo_final.tex
cd ..ai/templates/kx-paper/demo && pdflatex -interaction=nonstopmode demo_final.tex && pdflatex -interaction=nonstopmode demo_final.tex
```
(Run twice for correct TOC/references.)
