"""
Multi-modal Document Parser.
This module processes PDFs to extract text, tables, and images/charts
for injection into the multi-modal RAG vector store.
Uses IBM's Docling if available, falling back to PyMuPDF/PyPDF.
"""

import os
from typing import Dict, Any, List

def parse_document(file_path: str, output_image_dir: str = "data/process/images") -> Dict[str, Any]:
    """
    Parse a document to extract text, tables, and images/charts.
    
    Args:
        file_path: Path to the PDF file.
        output_image_dir: Directory where extracted images will be saved.
        
    Returns:
        A dictionary containing:
          - "text": The extracted text (in markdown if parsed via Docling).
          - "images": List of paths to the extracted images.
          - "tables": List of extracted table structures (if any).
    """
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"File not found: {file_path}")
        
    os.makedirs(output_image_dir, exist_ok=True)
    results = {
        "text": "",
        "images": [],
        "tables": []
    }
    
    # 1. Attempt to use IBM's Docling
    try:
        from docling.document_converter import DocumentConverter
        print(f"[VisionParser] Using IBM Docling to convert {os.path.basename(file_path)}...")
        
        converter = DocumentConverter()
        docling_doc = converter.convert(file_path)
        
        # Docling converts layout perfectly into markdown
        results["text"] = docling_doc.render_as_markdown()
        
        # If Docling's pipeline extracted images, gather them
        # (Docling can extract images and save them if export options are set)
        # For simplicity in this scaffold, we'll let docling do markdown & tables, 
        # and use PyMuPDF for visual image extraction.
        
    except ImportError:
        print("[VisionParser] IBM Docling not found. Falling back to PyMuPDF/PyPDF extraction...")
        # 2. Fallback to PyMuPDF (fitz) to extract text and actual images
        try:
            import fitz
            doc = fitz.open(file_path)
            text_blocks = []
            
            for page_num in range(len(doc)):
                page = doc[page_num]
                text_blocks.append(page.get_text())
                
                # Extract images on this page
                image_list = page.get_images(full=True)
                for img_idx, img in enumerate(image_list):
                    xref = img[0]
                    base_image = doc.extract_image(xref)
                    image_bytes = base_image["image"]
                    image_ext = base_image["ext"]
                    
                    image_name = f"{os.path.splitext(os.path.basename(file_path))[0]}_p{page_num}_img{img_idx}.{image_ext}"
                    image_path = os.path.join(output_image_dir, image_name)
                    
                    with open(image_path, "wb") as f:
                        f.write(image_bytes)
                        
                    results["images"].append(image_path)
                    
            results["text"] = "\n\n".join(text_blocks)
            
        except ImportError:
            # 3. Final raw text fallback using PyPDF
            print("[VisionParser] PyMuPDF not found. Falling back to standard PyPDF text extraction...")
            try:
                from pypdf import PdfReader
                reader = PdfReader(file_path)
                text_blocks = [page.extract_text() for page in reader.pages]
                results["text"] = "\n\n".join(text_blocks)
            except Exception as e:
                print(f"[VisionParser] Error during PyPDF fallback: {e}")
                
    print(f"[VisionParser] Parsing finished. Extracted {len(results['text'])} chars and {len(results['images'])} images.")
    return results

if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        print("Usage: python -m data.rag.vision_parser <path_to_pdf>")
        sys.exit(1)
        
    res = parse_document(sys.argv[1])
    print(f"Extracted Text Snippet:\n{res['text'][:300]}...")
