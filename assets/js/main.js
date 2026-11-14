// Mobile nav toggle
const navToggle = document.querySelector('.nav-toggle');
const navLinks  = document.querySelector('.nav-links');
navToggle.addEventListener('click', () => {
  const expanded = navToggle.getAttribute('aria-expanded') === 'true';
  navToggle.setAttribute('aria-expanded', String(!expanded));
  navLinks.classList.toggle('is-open');
});
navLinks.querySelectorAll('a').forEach(link => {
  link.addEventListener('click', () => {
    navLinks.classList.remove('is-open');
    navToggle.setAttribute('aria-expanded', 'false');
  });
});

// Sticky nav shadow on scroll
window.addEventListener('scroll', () => {
  document.querySelector('.site-nav').classList.toggle('scrolled', window.scrollY > 10);
}, { passive: true });
