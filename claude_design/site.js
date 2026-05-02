// Budgetella · Marketing site — shared chrome (nav + footer) + tiny scroll behaviors

(function () {
  // ── Nav (sticky, blur, scroll border) ──
  const navHTML = `
<nav class="nav" id="site-nav">
  <div class="nav-inner">
    <a href="index.html" class="brand" aria-label="Budgetella">
      <div class="brand-mark">B</div>
      <span>Budgetella</span>
    </a>
    <div class="nav-links">
      <a href="index.html#features" data-link="features">Özellikler</a>
      <a href="index.html#why" data-link="why">Neden</a>
      <a href="index.html#how" data-link="how">Nasıl çalışır</a>
      <a href="index.html#pricing" data-link="pricing">Fiyatlandırma</a>
      <a href="support.html" data-link="support">Destek</a>
    </div>
    <div class="nav-cta">
      <a href="#" class="btn btn-ghost">Giriş yap</a>
      <a href="#download" class="btn btn-primary">İndir</a>
    </div>
  </div>
</nav>
  `;

  // ── Footer ──
  const footerHTML = `
<footer class="footer">
  <div class="container">
    <div class="footer-grid">
      <div class="footer-brand">
        <div class="brand">
          <div class="brand-mark">B</div>
          <span>Budgetella</span>
        </div>
        <p class="lede">Türkçe konuşan kişisel finans asistanın. Banka bağlantısı yok, AI destekli, gizli.</p>
      </div>
      <div class="footer-col">
        <h4>Ürün</h4>
        <ul>
          <li><a href="index.html#features">Özellikler</a></li>
          <li><a href="index.html#pricing">Fiyatlandırma</a></li>
          <li><a href="index.html#download">İndir</a></li>
          <li><a href="index.html#faq">SSS</a></li>
        </ul>
      </div>
      <div class="footer-col">
        <h4>Şirket</h4>
        <ul>
          <li><a href="about.html">Hakkımızda</a></li>
          <li><a href="contact.html">İletişim</a></li>
          <li><a href="support.html">Destek</a></li>
        </ul>
      </div>
      <div class="footer-col">
        <h4>Yasal</h4>
        <ul>
          <li><a href="privacy.html">Gizlilik</a></li>
          <li><a href="terms.html">Kullanım Şartları</a></li>
          <li><a href="privacy.html#kvkk">KVKK</a></li>
        </ul>
      </div>
      <div class="footer-col">
        <h4>Sosyal</h4>
        <ul>
          <li><a href="#" target="_blank" rel="noopener">Twitter / X</a></li>
          <li><a href="#" target="_blank" rel="noopener">Instagram</a></li>
          <li><a href="#" target="_blank" rel="noopener">LinkedIn</a></li>
        </ul>
      </div>
    </div>
    <div class="footer-bottom">
      <span>© 2026 Budgetella · İstanbul</span>
      <span class="mono">v1.0 · 2 May 2026</span>
    </div>
  </div>
</footer>
  `;

  // Inject into placeholders
  const navMount = document.getElementById('mount-nav');
  const footerMount = document.getElementById('mount-footer');
  if (navMount) navMount.outerHTML = navHTML;
  if (footerMount) footerMount.outerHTML = footerHTML;

  // ── Scroll behavior — add .scrolled to nav when offset > 8 ──
  const nav = document.getElementById('site-nav');
  const onScroll = () => {
    if (!nav) return;
    if (window.scrollY > 8) nav.classList.add('scrolled');
    else nav.classList.remove('scrolled');
  };
  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();

  // ── Active page link in nav ──
  const path = location.pathname.split('/').pop() || 'index.html';
  const activeLink = path.replace('.html', '');
  document.querySelectorAll('.nav-links a').forEach(a => {
    if (a.dataset.link === activeLink) a.classList.add('active');
  });

  // ── Reveal-on-scroll using IntersectionObserver ──
  const io = new IntersectionObserver((entries) => {
    entries.forEach(e => {
      if (e.isIntersecting) {
        e.target.classList.add('in');
        io.unobserve(e.target);
      }
    });
  }, { threshold: 0.12, rootMargin: '0px 0px -50px 0px' });
  document.querySelectorAll('.reveal').forEach(el => io.observe(el));

  // ── Smooth scroll for in-page anchors ──
  document.querySelectorAll('a[href^="#"]').forEach(a => {
    a.addEventListener('click', (e) => {
      const id = a.getAttribute('href');
      if (id.length < 2) return;
      const target = document.querySelector(id);
      if (target) {
        e.preventDefault();
        const top = target.getBoundingClientRect().top + window.scrollY - 80;
        window.scrollTo({ top, behavior: 'smooth' });
      }
    });
  });
})();
