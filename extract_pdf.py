import sys
try:
    import PyPDF2
except ImportError:
    print("PyPDF2 not installed")
    sys.exit(1)

text = ""
with open("skillswap report.pdf", "rb") as f:
    reader = PyPDF2.PdfReader(f)
    for i, page in enumerate(reader.pages):
        text += f"\n--- Page {i+1} ---\n"
        text += page.extract_text()

with open("pdf_content.txt", "w", encoding="utf-8") as f:
    f.write(text)
print("Extracted PDF to pdf_content.txt")
