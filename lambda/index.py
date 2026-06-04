"""
AWS Lambda — Sponsor contact form handler (Python 3.12)

Traffic flow:
  Browser → CloudFront /api/sponsor → Lambda Function URL → this handler → SES

Security layers:
  1. CloudFront injects x-origin-secret; Lambda rejects calls without it.
  2. All inputs are validated server-side (length, format, allowlist).
  3. html.escape() from stdlib is used for HTML output — safer than a custom
     function because it also escapes quotes, preventing attribute injection.
  4. (TODO) Add Cloudflare Turnstile: verify the cf-turnstile-response token
     via https://challenges.cloudflare.com/turnstile/v0/siteverify using the
     secret key stored in TURNSTILE_SECRET_KEY env var.

Required environment variables:
  TO_EMAIL       – recipient address
  FROM_EMAIL     – SES-verified sender address
  ORIGIN_SECRET  – shared secret injected by CloudFront (see cloudfront.tf)

The Lambda execution role must have ses:SendEmail permission.
"""

import hmac
import html
import json
import os
import re

import boto3
from botocore.exceptions import ClientError

TO_EMAIL      = os.environ.get("TO_EMAIL", "")
FROM_EMAIL    = os.environ.get("FROM_EMAIL", "")
ORIGIN_SECRET = os.environ.get("ORIGIN_SECRET", "")

# ── Validation constants ───────────────────────────────────────────────────────
EMAIL_RE = re.compile(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,63}$')

VALID_INTERESTS = {"visibility", "talent", "speaking", "presence", "general"}

INTEREST_LABELS = {
    "visibility": "Visibilidad de marca",
    "talent":     "Acceso a talento",
    "speaking":   "Espacio para hablar en un evento",
    "presence":   "Presencia física en eventos",
    "general":    "Información general sobre patrocinio",
}

FIELD_LIMITS = {
    "name":    (1,   100),
    "email":   (1,   254),  # RFC 5321 max
    "company": (1,   200),
    "role":    (0,   100),
    "message": (20, 2000),
}

# ── CORS headers ──────────────────────────────────────────────────────────────
# Kept here for defence-in-depth even though the browser never calls the raw
# Lambda URL (CloudFront proxies all requests, making them same-origin).
CORS = {
    "Access-Control-Allow-Origin":  f"https://awsugmixtli.com",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
}


def _response(status_code: int, body: dict) -> dict:
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json", **CORS},
        "body": json.dumps(body),
    }


def _validate(payload: dict) -> tuple[dict | None, str | None]:
    """Validate and sanitise every field. Returns (clean_data, error_message)."""
    cleaned = {}

    # ── Required text fields ─────────────────────────────────────────────
    for field in ("name", "email", "company", "message"):
        raw = (payload.get(field) or "").strip()
        min_len, max_len = FIELD_LIMITS[field]

        if not raw:
            return None, "Faltan campos obligatorios."
        if len(raw) < min_len:
            return None, f"El campo '{field}' es demasiado corto."
        if len(raw) > max_len:
            return None, f"El campo '{field}' excede el límite permitido."

        cleaned[field] = raw

    # ── Email format ─────────────────────────────────────────────────────
    if not EMAIL_RE.match(cleaned["email"]):
        return None, "El correo electrónico no es válido."

    # ── Optional: role ───────────────────────────────────────────────────
    role = (payload.get("role") or "").strip()
    if len(role) > FIELD_LIMITS["role"][1]:
        return None, "El campo 'cargo' excede el límite permitido."
    cleaned["role"] = role

    # ── Optional: interest (must be an allowed key or absent) ────────────
    interest_key = (payload.get("interest") or "").strip()
    if interest_key and interest_key not in VALID_INTERESTS:
        return None, "Valor de interés no válido."
    cleaned["interest"] = INTEREST_LABELS.get(interest_key, "")

    return cleaned, None


# ── Build email content ───────────────────────────────────────────────────────
def _build_email(data: dict) -> dict:
    """Build plain-text and HTML email bodies from validated field data."""
    name     = data["name"]
    email    = data["email"]
    company  = data["company"]
    role     = data.get("role", "")
    interest = data.get("interest", "")
    message  = data["message"]

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

    # html.escape() is the right tool here:
    #   • Covers &, <, >, ", ' — the custom function only covered the first three.
    #   • Preventing quote escaping matters because values land inside HTML
    #     attributes (e.g. style="…") where an unescaped " would break out.
    #   • It is maintained by the Python team and follows the HTML spec.
    def row(line: str) -> str:
        return f'<p style="margin:4px 0">{html.escape(line)}</p>'

    html_lines = [("<br>" if ln == "" else row(ln)) for ln in text_lines]

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


# ── Send via SES ──────────────────────────────────────────────────────────────
def _send_ses(email_content: dict) -> None:
    ses = boto3.client("ses")
    ses.send_email(
        Source=FROM_EMAIL,
        Destination={"ToAddresses": [TO_EMAIL]},
        Message={
            "Subject": {"Data": email_content["subject"], "Charset": "UTF-8"},
            "Body": {
                "Text": {"Data": email_content["text"], "Charset": "UTF-8"},
                "Html": {"Data": email_content["html"], "Charset": "UTF-8"},
            },
        },
        ReplyToAddresses=[email_content["reply_to"]],
    )


# ── Lambda handler ────────────────────────────────────────────────────────────
def handler(event, context):
    headers = event.get("headers") or {}

    # 1. Origin secret — reject requests not arriving via CloudFront
    if ORIGIN_SECRET:
        incoming = headers.get("x-origin-secret", "")
        # hmac.compare_digest prevents timing side-channel attacks
        if not incoming or not hmac.compare_digest(incoming, ORIGIN_SECRET):
            print("Rejected: missing or invalid x-origin-secret")
            return _response(403, {"message": "Forbidden."})

    # 2. CORS preflight
    method = (
        event.get("requestContext", {})
             .get("http", {})
             .get("method", "")
    )
    if method == "OPTIONS":
        return _response(200, {})

    # 3. Parse body
    try:
        payload = json.loads(event.get("body") or "{}")
    except (json.JSONDecodeError, TypeError):
        return _response(400, {"message": "Solicitud inválida."})

    # 4. Validate all fields
    data, error = _validate(payload)
    if error:
        return _response(400, {"message": error})

    # 5. Sanity-check environment variables
    if not TO_EMAIL or not FROM_EMAIL:
        print("ERROR: Missing TO_EMAIL or FROM_EMAIL environment variables")
        return _response(500, {"message": "Error de configuración del servidor."})

    # 6. Send email
    try:
        _send_ses(_build_email(data))
        return _response(200, {"success": True, "message": "Solicitud enviada correctamente."})
    except ClientError as exc:
        error_code = exc.response["Error"]["Code"]
        print(f"SES ClientError [{error_code}]: {exc}")
        return _response(500, {"message": "No se pudo enviar el correo. Intenta de nuevo."})
    except Exception as exc:  # noqa: BLE001
        print(f"Unexpected error: {exc}")
        return _response(500, {"message": "No se pudo enviar el correo. Intenta de nuevo."})
