from firebase_functions import https_fn
from firebase_functions.params import SecretParam


from flask import Request, Response
from openai import OpenAI
import os, io, logging, json

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")

#  ---- Lazy init ----
client = None
vector_store = None
assistant = None

@https_fn.on_request(
    region="europe-central2",
    memory=2048,
    timeout_sec=540,
    secrets=[SecretParam("OPENAI_API_KEY"),
             SecretParam("VECTOR_STORE_ID")]   # opsiyonel
)
def analyze_pdf(req: Request) -> Response:
    global client, vector_store, assistant

    # İlk gerçek çağrıda OpenAI nesnelerini hazırla
    if client is None:
        api_key = os.getenv("OPENAI_API_KEY")
        client  = OpenAI(api_key=api_key)

        vs_id = os.getenv("VECTOR_STORE_ID")
        if vs_id:
            vector_store = client.vector_stores.retrieve(vs_id)
        else:
            vector_store = client.vector_stores.create(
                name="KullaniciBelgeleri",
                expires_after={"anchor": "last_active_at", "days": 30},
            )

        assistant = client.beta.assistants.create(
            name="Doktor Asistanı",
            model="gpt-4o",
            tools=[{"type": "file_search"}],
            tool_resources={"file_search": {"vector_store_ids": [vector_store.id]}},
            instructions=(
                "PDF’lerdeki tıbbi bilgileri doktor titizliğiyle incele. "
                "Kullanıcıya anlaşılır, empatik, kısa ama doyurucu özet sun. "
                "Tıbbi terimleri basitleştir; gerekirse doktora yönlendir."
            ),
        )
        logging.info("Assistant hazır: %s", assistant.id)

    # -------- İstek işleme --------
    if req.method != "POST":
        return Response("Only POST", status=405)

    pdf = req.files.get("file") if hasattr(req, "files") else None
    if pdf is None:
        return Response("PDF bulunamadı", status=400)

    try:
        stream = io.BytesIO(pdf.read())
        stream.name = pdf.filename or "upload.pdf"

        upload = client.files.create(file=stream, purpose="assistants")
        client.vector_stores.files.create(
            vector_store_id=vector_store.id, file_id=upload.id
        )
        client.vector_stores.files.poll(
            vector_store_id=vector_store.id, file_id=upload.id
        )

        thread = client.beta.threads.create()
        client.beta.threads.messages.create(
            thread_id=thread.id,
            role="user",
            content="Lütfen yüklediğim PDF’teki bilgileri analiz et ve özetle.",
        )
       
run = client.beta.threads.runs.create(
    thread_id=thread.id,
    assistant_id=assistant.id,
    tool_resources={
        "file_search": {
            "vector_store_ids": [vector_store.id],
            "file_ids": [upload.id]          # 👈  SADECE bu PDF
        }
    }
)
        client.beta.threads.runs.poll(thread_id=thread.id, run_id=run.id)

        msg = client.beta.threads.messages.list(thread_id=thread.id).data[0]
        answer = msg.content[0].text.value

        return Response(answer, mimetype="text/plain; charset=utf-8")

    except Exception as exc:
        logging.exception("Hata:")
        return Response(json.dumps({"error": str(exc)}, ensure_ascii=False),
                        mimetype="application/json", status=500)
