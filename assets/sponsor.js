// ── Sponsor form — validation & submission via serverless ─
//
// Delivery is handled by a Lambda Function URL that sends
// email through AWS SES. After running `terraform apply`,
// copy the `lambda_function_url` output value here.
//
const SUBMIT_ENDPOINT = 'YOUR_LAMBDA_FUNCTION_URL'; // terraform output lambda_function_url

(function () {
  const form      = document.getElementById('sponsor-form');
  const submitBtn = document.getElementById('form-submit');
  const successEl = document.getElementById('form-success');
  const errorEl   = document.getElementById('form-error-state');
  const errorMsg  = document.getElementById('form-error-msg');
  const retryBtn  = document.getElementById('form-retry-btn');
  if (!form) return;

  // ── Validation rules ──────────────────────────────────
  const rules = {
    'contact-name':    { required: true, label: 'El nombre es obligatorio.' },
    'contact-email':   { required: true, pattern: /^[^\s@]+@[^\s@]+\.[^\s@]+$/, label: 'Ingresa un correo válido.' },
    'contact-company': { required: true, label: 'El nombre de la empresa es obligatorio.' },
    'contact-message': { required: true, minLength: 20, label: 'El mensaje debe tener al menos 20 caracteres.' },
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
    } else if (rule.pattern && val && !rule.pattern.test(val)) {
      msg = rule.label;
    } else if (rule.minLength && val.length < rule.minLength) {
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

  // ── UI state helpers ───────────────────────────────────
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

  // ── Retry button ───────────────────────────────────────
  retryBtn.addEventListener('click', showForm);

  // ── Form submission ────────────────────────────────────
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    if (!validateAll()) return;

    setSubmitting(true);

    const interestLabels = {
      visibility: 'Visibilidad de marca',
      talent:     'Acceso a talento',
      speaking:   'Espacio para hablar en un evento',
      presence:   'Presencia física en eventos',
      general:    'Información general sobre patrocinio',
    };

    const name     = document.getElementById('contact-name').value.trim();
    const email    = document.getElementById('contact-email').value.trim();
    const company  = document.getElementById('contact-company').value.trim();
    const role     = document.getElementById('contact-role').value.trim();
    const interest = document.getElementById('contact-interest').value;
    const message  = document.getElementById('contact-message').value.trim();

    const payload = {
      name,
      email,
      company,
      role:     role     || null,
      interest: interest ? (interestLabels[interest] || interest) : null,
      message,
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
        // Lambda returned a non-2xx (e.g. SES/Postmark error)
        let detail = '';
        try { detail = (await res.json()).message || ''; } catch (_) {}
        showError(
          detail
            ? `No se pudo enviar tu solicitud: ${detail}`
            : 'El servidor rechazó la solicitud. Por favor intenta de nuevo o escríbenos directamente.'
        );
      }
    } catch (_) {
      // Network error / endpoint unreachable
      showError('No se pudo conectar con el servidor. Verifica tu conexión e intenta de nuevo.');
    }
  });
})();
