# python_backend/app.py
#
#  — Var olan Vector Store ID’si (.env içindeki VECTOR_STORE_ID) kullanılır.
#   Yoksa yeni bir tane oluşturulur ve ID’si log’a yazılır.
#   Yanıt düz metin (UTF-8) olarak döner.

from flask import Flask, request, Response, jsonify
from openai import OpenAI
from dotenv import load_dotenv
import os, io, pathlib, json, logging

# ─────────────────────────────────────────────
#  LOG AYARI
# ─────────────────────────────────────────────
logging.basicConfig(level=logging.INFO, format="%(levelname)s  %(message)s")

# ─────────────────────────────────────────────
#  .env → OPENAI_API_KEY ve varsa VECTOR_STORE_ID
#  ( ..\assets\.env )
# ─────────────────────────────────────────────
dotenv_path = pathlib.Path(__file__).resolve().parent.parent / "assets" / ".env"
load_dotenv(dotenv_path)

api_key         = os.getenv("OPENAI_API_KEY")
vector_store_id = os.getenv("VECTOR_STORE_ID")    # isteğe bağlı

if not api_key:
    raise SystemExit("‼  OPENAI_API_KEY bulunamadı")

# ─────────────────────────────────────────────
#  OpenAI İstemcisi
# ─────────────────────────────────────────────
client = OpenAI(api_key=api_key)
logging.info("✅  OpenAI client başlatıldı")

# ─────────────────────────────────────────────
#  Vector Store: mevcutsa getir, yoksa yarat
# ─────────────────────────────────────────────
if vector_store_id:
    VECTOR_STORE = client.vector_stores.retrieve(vector_store_id)
    logging.info(f"🗂  Mevcut Vector Store kullanılıyor → {VECTOR_STORE.id}")
else:
    VECTOR_STORE = client.vector_stores.create(
        name="KullaniciBelgeleri",
        expires_after={"anchor": "last_active_at", "days": 30},
    )
    logging.info(f"🗂  Yeni Vector Store oluşturuldu → {VECTOR_STORE.id}")

# ─────────────────────────────────────────────
#  Assistant
# ─────────────────────────────────────────────
ASSISTANT = client.beta.assistants.create(
    name="Doktor Asistanı",
    model="gpt-4o",
    instructions=(
        "PDF’lerdeki tıbbi bilgileri doktor titizliğiyle incele. "
        "Kullanıcıya anlaşılır, empatik, kısa ama doyurucu özet sun. "
        "Tıbbi terimleri basitleştir; gerekirse doktora yönlendir."
    ),
    tools=[{"type": "file_search"}],
    tool_resources={"file_search": {"vector_store_ids": [VECTOR_STORE.id]}},
)
logging.info(f"🤖  Assistant oluşturuldu → {ASSISTANT.id}")

# ─────────────────────────────────────────────
#  Flask Uygulaması
# ─────────────────────────────────────────────
app = Flask(__name__)

@app.route("/analyze", methods=["POST"])
def analyze():
    try:
        # 0) Dosya kontrolü
        pdf = request.files.get("file")
        if pdf is None:
            return jsonify({"error": "PDF bulunamadı"}), 400

        # 1) Dosyayı byte akışına çevir
        stream = io.BytesIO(pdf.read())
        stream.name = pdf.filename or "upload.pdf"

        # 2) OpenAI'ya dosyayı yükle
        upload = client.files.create(file=stream, purpose="assistants")

        # 3) Vector Store’a ekle + indeks bitene kadar bekle
        client.vector_stores.files.create(
            vector_store_id=VECTOR_STORE.id,
            file_id=upload.id,
        )
        client.vector_stores.files.poll(
            vector_store_id=VECTOR_STORE.id,
            file_id=upload.id,
        )

        # 4) Thread → mesaj → run
        thread = client.beta.threads.create()
        client.beta.threads.messages.create(
            thread_id=thread.id,
            role="user",
            content="Lütfen yüklediğim PDF’teki bilgileri analiz et ve özetle.",
        )

        run = client.beta.threads.runs.create(
            thread_id=thread.id,
            assistant_id=ASSISTANT.id,
        )
        client.beta.threads.runs.poll(thread_id=thread.id, run_id=run.id)

        # 5) Yanıtı al
        messages = client.beta.threads.messages.list(thread_id=thread.id)
        answer   = messages.data[0].content[0].text.value

        # 6) Düz metin döndür (UTF-8)
        return Response(answer, mimetype="text/plain; charset=utf-8")

    except Exception as e:
        logging.exception("🔥  Hata oluştu:")
        return jsonify({"error": str(e)}), 500

# ─────────────────────────────────────────────
#  Sunucuyu başlat
# ─────────────────────────────────────────────
if __name__ == "__main__":
    logging.info("🚀  Flask başlatılıyor…")
    app.run(host="0.0.0.0", port=5000, debug=True, use_reloader=False)
