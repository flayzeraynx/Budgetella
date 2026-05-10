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
      <a href="/index.html#download" class="btn btn-primary btn-lg">İndir</a>
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
        <div class="footer-social">
          <a href="https://x.com/budgetella_app" target="_blank" rel="noopener" aria-label="X / Twitter" class="social-link">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-4.714-6.231-5.401 6.231H2.744l7.73-8.835L1.254 2.25H8.08l4.253 5.622zm-1.161 17.52h1.833L7.084 4.126H5.117z"/></svg>
          </a>
          <a href="https://instagram.com/budgetella.app" target="_blank" rel="noopener" aria-label="Instagram" class="social-link">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="20" height="20" x="2" y="2" rx="5" ry="5"/><path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"/><line x1="17.5" x2="17.51" y1="6.5" y2="6.5"/></svg>
          </a>
        </div>
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
