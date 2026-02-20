"""
AWS Lambda — Sponsor contact form handler (Python 3.12)

Triggered via a Lambda Function URL (no API Gateway needed).
Sends email through AWS SES.

Required environment variables:
  TO_EMAIL    – recipient address
  FROM_EMAIL  – SES-verified sender address

The Lambda execution role must have ses:SendEmail permission.
"""

import json
import os
import boto3
from botocore.exceptions import ClientError

TO_EMAIL   = os.environ.get("TO_EMAIL", "")
FROM_EMAIL = os.environ.get("FROM_EMAIL", "")

# ── CORS headers ──────────────────────────────────────────
CORS = {
    "Access-Control-Allow-Origin":  "https://awsugmixtli.com",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
}


def _response(status_code: int, body: dict) -> dict:
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json", **CORS},
        "body": json.dumps(body),
    }


# ── Build email content ───────────────────────────────────
def _build_email(payload: dict) -> dict:
    name     = payload.get("name", "")
    email    = payload.get("email", "")
    company  = payload.get("company", "")
    role     = payload.get("role") or ""
    interest = payload.get("interest") or ""
    message  = payload.get("message", "")

    subject = f"[Patrocinio] {company} — {name}"

    text_lines = [
        f"Nombre:   {name}",
        f"Correo:   {email}",
        f"Empresa:  {company}",
    ]
    if role:
        text_lines.append(f"Cargo:    {role}")
    if interest:
        text_lines.append(f"Interés:  {interest}")
    text_lines += ["", "Mensaje:", message]

    def _escape(s: str) -> str:
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

    html_lines = []
    for line in text_lines:
        if line == "":
            html_lines.append("<br>")
        else:
            html_lines.append(f'<p style="margin:4px 0">{_escape(line)}</p>')

    html_body = f"""
      <div style="font-family:Arial,sans-serif;font-size:14px;color:#222;max-width:600px">
        <h2 style="color:#A166FF">Nueva solicitud de patrocinio</h2>
        {"".join(html_lines)}
        <hr style="margin-top:24px;border:none;border-top:1px solid #eee">
        <p style="color:#888;font-size:12px">
          Enviado desde el formulario de patrocinio de
          <a href="https://awsugmixtli.com">awsugmixtli.com</a>
        </p>
      </div>"""

    return {
        "subject":  subject,
        "text":     "\n".join(text_lines),
        "html":     html_body,
        "reply_to": email,
    }


# ── Send via SES ──────────────────────────────────────────
def _send_ses(email: dict) -> None:
    ses = boto3.client("ses")
    ses.send_email(
        Source=FROM_EMAIL,
        Destination={"ToAddresses": [TO_EMAIL]},
        Message={
            "Subject": {"Data": email["subject"], "Charset": "UTF-8"},
            "Body": {
                "Text": {"Data": email["text"], "Charset": "UTF-8"},
                "Html": {"Data": email["html"], "Charset": "UTF-8"},
            },
        },
        ReplyToAddresses=[email["reply_to"]],
    )


# ── Lambda handler ────────────────────────────────────────
def handler(event, context):
    # Handle CORS preflight
    method = (
        event.get("requestContext", {})
             .get("http", {})
             .get("method", "")
    )
    if method == "OPTIONS":
        return _response(200, {})

    # Parse body
    try:
        payload = json.loads(event.get("body") or "{}")
    except (json.JSONDecodeError, TypeError):
        return _response(400, {"message": "Solicitud inválida."})

    # Validate required fields
    name    = (payload.get("name")    or "").strip()
    email   = (payload.get("email")   or "").strip()
    company = (payload.get("company") or "").strip()
    message = (payload.get("message") or "").strip()

    if not all([name, email, company, message]):
        return _response(400, {"message": "Faltan campos obligatorios."})

    if not TO_EMAIL or not FROM_EMAIL:
        print("ERROR: Missing TO_EMAIL or FROM_EMAIL environment variables")
        return _response(500, {"message": "Error de configuración del servidor."})

    email_content = _build_email(payload)

    try:
        _send_ses(email_content)
        return _response(200, {"success": True, "message": "Solicitud enviada correctamente."})
    except ClientError as exc:
        error_code = exc.response["Error"]["Code"]
        print(f"SES ClientError [{error_code}]: {exc}")
        return _response(500, {"message": "No se pudo enviar el correo. Intenta de nuevo."})
    except Exception as exc:  # noqa: BLE001
        print(f"Unexpected error: {exc}")
        return _response(500, {"message": "No se pudo enviar el correo. Intenta de nuevo."})
