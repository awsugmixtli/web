// ── Sponsor form — validation & submission via CloudFront proxy ─
//
// Requests go to /api/sponsor on the same CloudFront origin.
// CloudFront proxies them to the Lambda Function URL and injects
// the x-origin-secret header, so the raw Lambda URL is never exposed.
//
const SUBMIT_ENDPOINT = '/api/sponsor';

(function () {
  const form      = document.getElementById('sponsor-form');
  const submitBtn = document.getElementById('form-submit');
  const successEl = document.getElementById('form-success');
  const errorEl   = document.getElementById('form-error-state');
  const errorMsg  = document.getElementById('form-error-msg');
  const retryBtn  = document.getElementById('form-retry-btn');
  if (!form) return;

  // ── Validation rules ──────────────────────────────────────────────────
  // Keep length limits in sync with FIELD_LIMITS in lambda/index.py.
  const rules = {
    'contact-name': {
      required: true,
      maxLength: 100,
      label:    'El nombre es obligatorio.',
      maxLabel: 'El nombre no puede superar 100 caracteres.',
    },
    'contact-email': {
      required: true,
      maxLength: 254,
      // Matches the regex in index.py — intentionally kept simple
      pattern:  /^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,63}$/,
      label:    'Ingresa un correo electrónico válido.',
      maxLabel: 'El correo no puede superar 254 caracteres.',
    },
    'contact-company': {
      required: true,
      maxLength: 200,
      label:    'El nombre de la empresa es obligatorio.',
      maxLabel: 'El nombre de empresa no puede superar 200 caracteres.',
    },
    'contact-message': {
      required:  true,
      minLength: 20,
      maxLength: 2000,
      label:     'El mensaje debe tener al menos 20 caracteres.',
      maxLabel:  'El mensaje no puede superar 2 000 caracteres.',
    },
  };

  function validateField(id) {
    const field = document.getElementById(id);
    const rule  = rules[id];
    const error = document.getElementById('error-' + id.replace('contact-', ''));
    if (!field || !rule || !error) return true;

    const val = field.value.trim();
    let msg = '';

    if (rule.required && !val) {
      msg = rule.label;
    } else if (val && rule.maxLength && val.length > rule.maxLength) {
      msg = rule.maxLabel;
    } else if (val && rule.pattern && !rule.pattern.test(val)) {
      msg = rule.label;
    } else if (val && rule.minLength && val.length < rule.minLength) {
      msg = rule.label;
    }

    error.textContent = msg;
    field.classList.toggle('has-error', !!msg);
    return !msg;
  }

  function validateAll() {
    return Object.keys(rules).map(validateField).every(Boolean);
  }

  // Live validation on blur
  Object.keys(rules).forEach(id => {
    const field = document.getElementById(id);
    if (field) field.addEventListener('blur', () => validateField(id));
  });

  // ── UI state helpers ──────────────────────────────────────────────────
  function showForm() {
    form.hidden        = false;
    successEl.hidden   = true;
    errorEl.hidden     = true;
    submitBtn.disabled = false;
    submitBtn.textContent = 'Enviar solicitud';
  }

  function showSuccess() {
    form.hidden      = true;
    successEl.hidden = false;
    errorEl.hidden   = true;
    successEl.scrollIntoView({ behavior: 'smooth', block: 'center' });
  }

  function showError(msg) {
    form.hidden      = true;
    successEl.hidden = true;
    errorEl.hidden   = false;
    if (msg) errorMsg.textContent = msg;
    errorEl.scrollIntoView({ behavior: 'smooth', block: 'center' });
  }

  function setSubmitting(loading) {
    submitBtn.disabled    = loading;
    submitBtn.textContent = loading ? 'Enviando…' : 'Enviar solicitud';
  }

  // ── Retry button ──────────────────────────────────────────────────────
  retryBtn.addEventListener('click', showForm);

  // ── Form submission ───────────────────────────────────────────────────
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    if (!validateAll()) return;

    setSubmitting(true);

    // Send the raw <select> key value; the Lambda maps it to a
    // human-readable label. Allowed: visibility | talent | speaking |
    // presence | general (must match VALID_INTERESTS in index.py).
    const payload = {
      name:     document.getElementById('contact-name').value.trim(),
      email:    document.getElementById('contact-email').value.trim(),
      company:  document.getElementById('contact-company').value.trim(),
      role:     document.getElementById('contact-role').value.trim()    || null,
      interest: document.getElementById('contact-interest').value       || null,
      message:  document.getElementById('contact-message').value.trim(),
    };

    try {
      const res = await fetch(SUBMIT_ENDPOINT, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify(payload),
      });

      if (res.ok) {
        showSuccess();
      } else {
        let detail = '';
        try { detail = (await res.json()).message || ''; } catch (_) {}
        showError(
          detail
            ? `No se pudo enviar tu solicitud: ${detail}`
            : 'El servidor rechazó la solicitud. Por favor intenta de nuevo o escríbenos directamente.'
        );
      }
    } catch (_) {
      showError('No se pudo conectar con el servidor. Verifica tu conexión e intenta de nuevo.');
    } finally {
      setSubmitting(false);
    }
  });
})();
