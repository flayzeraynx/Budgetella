// Budgetella · Marketing site — shared chrome (nav + footer) + scroll behaviors

(function () {
  const navHTML = `
<nav class="nav" id="site-nav">
  <div class="nav-inner">
    <a href="/index.html" class="brand" aria-label="Budgetella">
      <div class="brand-mark">B</div>
      <span>Budgetella</span>
    </a>
    <div class="nav-links">
      <a href="/index.html#features" data-link="features">Özellikler</a>
      <a href="/index.html#how" data-link="how">Nasıl çalışır</a>
      <a href="/index.html#pricing" data-link="pricing">Fiyatlandırma</a>
      <a href="/support.html" data-link="support">Destek</a>
    </div>
    <div class="nav-cta">
          <div class="lang-toggle">
            <a href="/" class="lang-btn" id="lang-en">EN</a>
            <span class="lang-sep">|</span>
            <a href="/tr" class="lang-btn" id="lang-tr">TR</a>
          </div>
      <a href="/index.html#download" class="btn btn-primary btn-lg" id="nav-cta">İndir</a>
    </div>
  </div>
</nav>`;

  const footerHTML = `
<footer class="footer">
  <div class="container">
    <div class="footer-grid">
      <div class="footer-brand">
        <div class="brand">
          <div class="brand-mark">B</div>
          <span>Budgetella</span>
        </div>
        <p class="lede">Harcamalarını takip et, bütçeni yönet, finansal hedeflerine ulaş. Sade, hızlı ve güvenli.</p>
        <p style="margin-top:14px; font-size:13px; color:var(--muted);">
          <a href="mailto:info@budgetella.app" style="color:var(--accent)">info@budgetella.app</a>
        </p>
        <!-- social-links-placeholder -->
      </div>
      <div class="footer-cols-row">
        <div class="footer-col">
          <h4>Ürün</h4>
          <ul>
            <li><a href="/index.html#features">Özellikler</a></li>
            <li><a href="/index.html#pricing">Fiyatlandırma</a></li>
            <li><a href="/index.html#download">İndir</a></li>
            <li><a href="/index.html#faq">SSS</a></li>
            <li><a href="/blog.html">Blog</a></li>
          </ul>
        </div>
        <div class="footer-col">
          <h4>Yasal</h4>
          <ul>
            <li><a href="/privacy.html">Gizlilik</a></li>
            <li><a href="/terms.html">Kullanım Şartları</a></li>
            <li><a href="/privacy.html#kvkk">KVKK</a></li>
          </ul>
        </div>
        <div class="footer-col">
          <h4>Destek</h4>
          <ul>
            <li><a href="/support.html">Yardım Merkezi</a></li>
            <li><a href="mailto:support@budgetella.app">Destek</a></li>
            <li><a href="https://apps.apple.com/account/subscriptions" target="_blank" rel="noopener">Abonelik</a></li>
          </ul>
        </div>
      </div>
    </div>
    <div class="footer-bottom">
      <span>© 2026 Budgetella</span>
      <span class="mono">v1.0 · iOS</span>
      <span class="mono" style="display:flex;gap:8px"><a href="/" style="opacity:0.6;transition:opacity 200ms" onmouseover="this.style.opacity=1" onmouseout="this.style.opacity=0.6">EN</a> · <a href="/tr" style="opacity:0.6;transition:opacity 200ms" onmouseover="this.style.opacity=1" onmouseout="this.style.opacity=0.6">TR</a></span>
    </div>
  </div>
</footer>`;

  const navMount = document.getElementById('mount-nav');
  const footerMount = document.getElementById('mount-footer');
  if (navMount) navMount.outerHTML = navHTML;
  if (footerMount) footerMount.outerHTML = footerHTML;

  // Scroll border on nav
  const nav = document.getElementById('site-nav');
  const onScroll = () => {
    if (!nav) return;
    nav.classList.toggle('scrolled', window.scrollY > 8);
  };
  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();

  // Active page link
  const path = location.pathname.split('/').pop() || 'index.html';
  const activeLink = path.replace('.html', '');
  document.querySelectorAll('.nav-links a').forEach(a => {
    if (a.dataset.link === activeLink) a.classList.add('active');
  });

  // Reveal on scroll
  const io = new IntersectionObserver((entries) => {
    entries.forEach(e => {
      if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); }
    });
  }, { threshold: 0.1, rootMargin: '0px 0px -40px 0px' });
  document.querySelectorAll('.reveal').forEach(el => io.observe(el));

  // Smooth scroll
  document.querySelectorAll('a[href^="#"]').forEach(a => {
    a.addEventListener('click', (e) => {
      const id = a.getAttribute('href');
      if (id.length < 2) return;
      const target = document.querySelector(id);
      if (target) {
        e.preventDefault();
        window.scrollTo({ top: target.getBoundingClientRect().top + window.scrollY - 80, behavior: 'smooth' });
      }
    });
  });
})();
