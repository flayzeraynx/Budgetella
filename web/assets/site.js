// Budgetella · Marketing site — shared chrome (nav + footer) + scroll behaviors

(function () {
  const isTR = document.documentElement.lang === 'tr';

  // ── Language-aware content ────────────────────────────────
  const t = isTR ? {
    features:    'Özellikler',
    how:         'Nasıl çalışır',
    pricing:     'Fiyatlandırma',
    support:     'Destek',
    download:    'İndir',
    tagline:     'Harcamalarını takip et, bütçeni yönet, finansal hedeflerine ulaş. Sade, hızlı ve güvenli.',
    product:     'Ürün',
    legal:       'Yasal',
    supportCol:  'Destek',
    feat_link:   'Özellikler',
    price_link:  'Fiyatlandırma',
    dl_link:     'İndir',
    faq_link:    'SSS',
    blog_link:   'Blog',
    privacy_link:'Gizlilik Politikası',
    terms_link:  'Kullanım Şartları',
    help_link:   'Yardım Merkezi',
    sub_link:    'Abonelik',
    home:        '/tr',
    feat_href:   '/tr#features',
    how_href:    '/tr#how',
    price_href:  '/tr#pricing',
    dl_href:     '/tr#download',
    faq_href:    '/tr#faq',
    blog_href:   '/blog-tr',
    privacy_href:'/privacy-tr',
    terms_href:  '/terms-tr',
    support_href:'/support-tr',
  } : {
    features:    'Features',
    how:         'How it works',
    pricing:     'Pricing',
    support:     'Support',
    download:    'Download',
    tagline:     'Track your spending, manage your budget, reach your financial goals. Simple, fast, and private.',
    product:     'Product',
    legal:       'Legal',
    supportCol:  'Support',
    feat_link:   'Features',
    price_link:  'Pricing',
    dl_link:     'Download',
    faq_link:    'FAQ',
    blog_link:   'Blog',
    privacy_link:'Privacy Policy',
    terms_link:  'Terms of Use',
    help_link:   'Help Center',
    sub_link:    'Subscription',
    home:        '/',
    feat_href:   '/#features',
    how_href:    '/#how',
    price_href:  '/#pricing',
    dl_href:     '/#download',
    faq_href:    '/#faq',
    blog_href:   '/blog',
    privacy_href:'/privacy',
    terms_href:  '/terms',
    support_href:'/support',
  };

  // ── Nav ───────────────────────────────────────────────────
  const navHTML = `
<nav class="nav" id="site-nav">
  <div class="nav-inner">
    <a href="${t.home}" class="brand" aria-label="Budgetella">
      <div class="brand-mark">B</div>
      <span>Budgetella</span>
    </a>
    <div class="nav-links">
      <a href="${t.feat_href}"  data-link="features">${t.features}</a>
      <a href="${t.how_href}"   data-link="how">${t.how}</a>
      <a href="${t.price_href}" data-link="pricing">${t.pricing}</a>
      <a href="${t.blog_href}" data-link="blog">${t.blog_link}</a>
      <a href="${t.support_href}" data-link="support">${t.support}</a>
    </div>
    <div class="nav-cta">
      <div class="lang-toggle">
        <a href="/"   class="lang-btn" id="lang-en">EN</a>
        <span class="lang-sep">|</span>
        <a href="/tr" class="lang-btn" id="lang-tr">TR</a>
      </div>
      <a href="${t.dl_href}" class="btn btn-primary btn-lg" id="nav-cta">${t.download}</a>
    </div>
  </div>
</nav>`;

  // ── Footer ────────────────────────────────────────────────
  const footerHTML = `
<footer class="footer">
  <div class="container">
    <div class="footer-grid">
      <div class="footer-brand">
        <div class="brand">
          <div class="brand-mark">B</div>
          <span>Budgetella</span>
        </div>
        <p class="lede">${t.tagline}</p>
        <p style="margin-top:14px;font-size:13px;color:var(--muted)">
          <a href="mailto:info@budgetella.app" style="color:var(--accent)">info@budgetella.app</a>
        </p>
      </div>
      <div class="footer-cols-row">
        <div class="footer-col">
          <h4>${t.product}</h4>
          <ul>
            <li><a href="${t.feat_href}">${t.feat_link}</a></li>
            <li><a href="${t.price_href}">${t.price_link}</a></li>
            <li><a href="${t.dl_href}">${t.dl_link}</a></li>
            <li><a href="${t.faq_href}">${t.faq_link}</a></li>
            <li><a href="${t.blog_href}">${t.blog_link}</a></li>
          </ul>
        </div>
        <div class="footer-col">
          <h4>${t.legal}</h4>
          <ul>
            <li><a href="${t.privacy_href}">${t.privacy_link}</a></li>
            <li><a href="${t.terms_href}">${t.terms_link}</a></li>
          </ul>
        </div>
        <div class="footer-col">
          <h4>${t.supportCol}</h4>
          <ul>
            <li><a href="${t.support_href}">${t.help_link}</a></li>
            <li><a href="mailto:support@budgetella.app">support@budgetella.app</a></li>
            <li><a href="https://apps.apple.com/account/subscriptions" target="_blank" rel="noopener">${t.sub_link}</a></li>
          </ul>
        </div>
      </div>
    </div>
    <div class="footer-bottom">
      <span>© 2026 Budgetella</span>
      <span class="mono">v1.0 · iOS</span>
      <span class="mono" style="display:flex;gap:8px">
        <a href="/"   style="opacity:0.6;transition:opacity 200ms" onmouseover="this.style.opacity=1" onmouseout="this.style.opacity=0.6">EN</a>
        ·
        <a href="/tr" style="opacity:0.6;transition:opacity 200ms" onmouseover="this.style.opacity=1" onmouseout="this.style.opacity=0.6">TR</a>
      </span>
    </div>
  </div>
</footer>`;

  // ── Mount ─────────────────────────────────────────────────
  const navMount = document.getElementById('mount-nav');
  const footerMount = document.getElementById('mount-footer');
  if (navMount) navMount.outerHTML = navHTML;
  if (footerMount) footerMount.outerHTML = footerHTML;

  // Scroll border on nav
  const nav = document.getElementById('site-nav');
  const onScroll = () => { if (nav) nav.classList.toggle('scrolled', window.scrollY > 8); };
  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();

  // Active page link
  const path = location.pathname;
  document.querySelectorAll('.nav-links a').forEach(a => {
    const href = a.getAttribute('href');
    if (href && !href.includes('#') && path === href) a.classList.add('active');
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

  // Footer social styles
})();
