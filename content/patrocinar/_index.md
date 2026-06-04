---
title: "Patrocina al AWS UG Mixtli"
description: "Conecta tu empresa con más de 400 profesionales AWS en Puebla. Conoce las opciones de patrocinio."
layout: "single"
aliases:
  - /sponsor.html
---

<form class="sponsor-form" id="sponsor-form" novalidate>
  <div class="form-row">
    <div class="form-group">
      <label class="form-label" for="contact-name">Nombre completo <span class="form-required" aria-hidden="true">*</span></label>
      <input
        class="form-input"
        type="text"
        id="contact-name"
        name="name"
        placeholder="Tu nombre"
        autocomplete="name"
        required>
      <span class="form-error" id="error-name" aria-live="polite"></span>
    </div>
    <div class="form-group">
      <label class="form-label" for="contact-email">Correo electrónico <span class="form-required" aria-hidden="true">*</span></label>
      <input
        class="form-input"
        type="email"
        id="contact-email"
        name="email"
        placeholder="tu@empresa.com"
        autocomplete="email"
        required>
      <span class="form-error" id="error-email" aria-live="polite"></span>
    </div>
  </div>

  <div class="form-row">
    <div class="form-group">
      <label class="form-label" for="contact-company">Empresa <span class="form-required" aria-hidden="true">*</span></label>
      <input
        class="form-input"
        type="text"
        id="contact-company"
        name="company"
        placeholder="Nombre de tu empresa"
        autocomplete="organization"
        required>
      <span class="form-error" id="error-company" aria-live="polite"></span>
    </div>
    <div class="form-group">
      <label class="form-label" for="contact-role">Cargo</label>
      <input
        class="form-input"
        type="text"
        id="contact-role"
        name="role"
        placeholder="Tu cargo en la empresa"
        autocomplete="organization-title">
    </div>
  </div>

  <div class="form-group">
    <label class="form-label" for="contact-interest">¿Qué te interesa más?</label>
    <select class="form-input form-select" id="contact-interest" name="interest">
      <option value="" disabled selected>Selecciona una opción</option>
      <option value="visibility">Visibilidad de marca</option>
      <option value="talent">Acceso a talento</option>
      <option value="speaking">Espacio para hablar en un evento</option>
      <option value="presence">Presencia física en eventos</option>
      <option value="general">Información general sobre patrocinio</option>
    </select>
  </div>

  <div class="form-group">
    <label class="form-label" for="contact-message">Mensaje <span class="form-required" aria-hidden="true">*</span></label>
    <textarea
      class="form-input form-textarea"
      id="contact-message"
      name="message"
      placeholder="Cuéntanos sobre tu empresa y cómo te gustaría colaborar con la comunidad..."
      rows="5"
      required></textarea>
    <span class="form-error" id="error-message" aria-live="polite"></span>
  </div>

  <div class="form-footer">
    <p class="form-note">
      <span aria-hidden="true">*</span> Campos obligatorios. Tu información no será compartida con terceros.
    </p>
    <button type="submit" class="btn btn-primary form-submit" id="form-submit">
      Enviar solicitud
    </button>
  </div>
</form>

<!-- Success state -->
<div class="form-success" id="form-success" hidden aria-live="polite">
  <svg class="form-success-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true">
    <path d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
  </svg>
  <h3>¡Solicitud enviada!</h3>
  <p>Gracias por tu interés en patrocinar al AWS UG Mixtli.<br>Nos pondremos en contacto contigo pronto.</p>
  <a href="/" class="btn btn-ghost">Volver al inicio</a>
</div>

<!-- Error state -->
<div class="form-error-state" id="form-error-state" hidden aria-live="polite">
  <svg class="form-error-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true">
    <path d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z"/>
  </svg>
  <h3>No se pudo enviar</h3>
  <p id="form-error-msg">Ocurrió un error al enviar tu solicitud. Por favor intenta de nuevo.</p>
  <button type="button" class="btn btn-primary" id="form-retry-btn">
    Intentar de nuevo
  </button>
</div>
