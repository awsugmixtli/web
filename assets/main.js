// ── Year in footer ──────────────────────
document.getElementById('year').textContent = new Date().getFullYear();

// ── Mobile nav toggle ───────────────────
const navToggle = document.querySelector('.nav-toggle');
const navLinks  = document.querySelector('.nav-links');
navToggle.addEventListener('click', () => {
  const expanded = navToggle.getAttribute('aria-expanded') === 'true';
  navToggle.setAttribute('aria-expanded', String(!expanded));
  navLinks.classList.toggle('is-open');
});
// Close mobile menu on link click
navLinks.querySelectorAll('a').forEach(link => {
  link.addEventListener('click', () => {
    navLinks.classList.remove('is-open');
    navToggle.setAttribute('aria-expanded', 'false');
  });
});

// ── Sticky nav shadow on scroll ─────────
window.addEventListener('scroll', () => {
  document.querySelector('.site-nav').classList.toggle('scrolled', window.scrollY > 10);
}, { passive: true });

// ── Next event via Meetup iCal feed ────
(async function loadNextEvent() {
  const skeleton = document.getElementById('event-skeleton');
  const content  = document.getElementById('event-content');
  const fallback = document.getElementById('event-fallback');

  // Parse a DTSTART value like 20260226T233000Z or 20260226T183000
  function parseIcalDate(val) {
    // Strip TZID param if present (e.g. DTSTART;TZID=America/New_York:...)
    const str = val.includes(':') ? val.split(':').pop() : val;
    const y = str.slice(0,4), mo = str.slice(4,6), d = str.slice(6,8);
    const h = str.slice(9,11), mi = str.slice(11,13), s = str.slice(13,15) || '00';
    const utc = str.endsWith('Z');
    return utc
      ? new Date(`${y}-${mo}-${d}T${h}:${mi}:${s}Z`)
      : new Date(`${y}-${mo}-${d}T${h}:${mi}:${s}`);
  }

  // Unfold iCal lines (RFC 5545: continuation lines start with a space/tab)
  function unfold(text) {
    return text.replace(/\r\n[ \t]/g, '').replace(/\n[ \t]/g, '');
  }

  // Extract the value of a property, handling key:value and key;params:value
  function prop(block, name) {
    const re = new RegExp(`^${name}(?:;[^:]*)?:(.*)`, 'm');
    const m  = block.match(re);
    return m ? m[1].trim() : null;
  }

  // Decode iCal text escaping (\n \, \; \:)
  function decode(str) {
    return str
      .replace(/\\n/gi, '\n')
      .replace(/\\,/g, ',')
      .replace(/\\;/g, ';')
      .replace(/\\\\/g, '\\');
  }

  // Show skeleton while loading
  skeleton.hidden = false;

  try {
    // Meetup's iCal endpoint doesn't include CORS headers, so we route the
    // request through a public CORS proxy. Replace this URL with your own
    // proxy or serverless function when one is available.
    const ICAL_URL = 'https://www.meetup.com/awsugmixtli/events/ical';
    const res = await fetch(`https://corsproxy.io/?url=${encodeURIComponent(ICAL_URL)}`);
    if (!res.ok) throw new Error('Feed unavailable');
    const raw = unfold(await res.text());

    // Split into VEVENT blocks
    const blocks = [];
    const re = /BEGIN:VEVENT([\s\S]*?)END:VEVENT/g;
    let m;
    while ((m = re.exec(raw)) !== null) blocks.push(m[1]);

    if (!blocks.length) throw new Error('No events in feed');

    const now = Date.now();

    // Find the next upcoming event
    const upcoming = blocks
      .map(b => ({
        title: decode(prop(b, 'SUMMARY') || ''),
        start: parseIcalDate(prop(b, 'DTSTART') || ''),
        url:   prop(b, 'URL') || 'https://www.meetup.com/awsugmixtli/events/',
        desc:  decode(prop(b, 'DESCRIPTION') || ''),
      }))
      .filter(ev => ev.start && ev.start.getTime() >= now)
      .sort((a, b) => a.start - b.start)[0];

    if (!upcoming) throw new Error('No upcoming events');

    // Extract location from DESCRIPTION (Meetup embeds it as "📍 **Lugar:** ...")
    const locMatch = upcoming.desc.match(/Lugar[:\s]+([^\n\\]+)/i);
    const venue = locMatch ? locMatch[1].replace(/\*+/g, '').trim() : null;

    const dateStr = upcoming.start.toLocaleDateString('es-MX', {
      weekday: 'long', year: 'numeric', month: 'long', day: 'numeric'
    });
    const timeStr = upcoming.start.toLocaleTimeString('es-MX', {
      hour: '2-digit', minute: '2-digit', hour12: true
    });

    document.getElementById('event-date').textContent = dateStr;
    document.getElementById('event-time').textContent = timeStr;
    document.getElementById('event-title').textContent = upcoming.title;
    if (venue) document.getElementById('event-venue').textContent = '📍 ' + venue;
    document.getElementById('event-link').href = upcoming.url;

    skeleton.hidden = true;
    content.hidden  = false;

  } catch (_) {
    skeleton.hidden = true;
    fallback.hidden = false;
  }
})();
