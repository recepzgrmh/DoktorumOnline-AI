from fastapi import FastAPI, File, UploadFile
import openai
import os
from PyPDF2 import PdfReader
from tempfile import NamedTemporaryFile

openai.api_key = os.getenv("OPENAI_API_KEY")

app = FastAPI()

def extract_text_from_pdf(pdf_file_path):
    reader = PdfReader(pdf_file_path)
    text = ""
    for page in reader.pages:
        page_text = page.extract_text()
        if page_text:
            text += page_text
    return text

@app.post("/upload_pdf/")
async def upload_pdf(file: UploadFile = File(...)):
    # Dosyayı geçici olarak kaydet
    with NamedTemporaryFile(delete=False, suffix=".pdf") as tmp:
        contents = await file.read()
        tmp.write(contents)
        tmp.flush()
        tmp_name = tmp.name

    # PDF'den metni çıkar
    text = extract_text_from_pdf(tmp_name)

    # OpenAI Files API'ye yükle
    openai_file = openai.files.create(
        file=open(tmp_name, "rb"),
        purpose="assistants"
    )
    file_id = openai_file.id

    # Sağlık yorumunu analiz et
    prompt = f"PDF içeriği: {text[:3000]}\nPDF’lerdeki tıbbi bilgileri doktor titizliğiyle incele. Kullanıcıya anlaşılır, empatik, kısa ama doyurucu özet sun.Tıbbi terimleri basitleştir; gerekirse doktora yönlendir."
    chat = openai.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": "Sen bir tıbbi asistansın."},
            {"role": "user", "content": prompt}
        ],
        max_tokens=500,
        temperature=0.7,
    )
    analysis = chat.choices[0].message.content.strip()

    return {"file_id": file_id, "analysis": analysis}
