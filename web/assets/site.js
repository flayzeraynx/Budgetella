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

  // ── Social (one line per account; paths from simple-icons) ─
  const socials = [
    { name: 'Instagram', tr: "Instagram'da", href: 'https://www.instagram.com/budgetella.app/', d: 'M7.0301.084c-1.2768.0602-2.1487.264-2.911.5634-.7888.3075-1.4575.72-2.1228 1.3877-.6652.6677-1.075 1.3368-1.3802 2.127-.2954.7638-.4956 1.6365-.552 2.914-.0564 1.2775-.0689 1.6882-.0626 4.947.0062 3.2586.0206 3.6671.0825 4.9473.061 1.2765.264 2.1482.5635 2.9107.308.7889.72 1.4573 1.388 2.1228.6679.6655 1.3365 1.0743 2.1285 1.38.7632.295 1.6361.4961 2.9134.552 1.2773.056 1.6884.069 4.9462.0627 3.2578-.0062 3.668-.0207 4.9478-.0814 1.28-.0607 2.147-.2652 2.9098-.5633.7889-.3086 1.4578-.72 2.1228-1.3881.665-.6682 1.0745-1.3378 1.3795-2.1284.2957-.7632.4966-1.636.552-2.9124.056-1.2809.0692-1.6898.063-4.948-.0063-3.2583-.021-3.6668-.0817-4.9465-.0607-1.2797-.264-2.1487-.5633-2.9117-.3084-.7889-.72-1.4568-1.3876-2.1228C21.2982 1.33 20.628.9208 19.8378.6165 19.074.321 18.2017.1197 16.9244.0645 15.6471.0093 15.236-.005 11.977.0014 8.718.0076 8.31.0215 7.0301.0839m.1402 21.6932c-1.17-.0509-1.8053-.2453-2.2287-.408-.5606-.216-.96-.4771-1.3819-.895-.422-.4178-.6811-.8186-.9-1.378-.1644-.4234-.3624-1.058-.4171-2.228-.0595-1.2645-.072-1.6442-.079-4.848-.007-3.2037.0053-3.583.0607-4.848.05-1.169.2456-1.805.408-2.2282.216-.5613.4762-.96.895-1.3816.4188-.4217.8184-.6814 1.3783-.9003.423-.1651 1.0575-.3614 2.227-.4171 1.2655-.06 1.6447-.072 4.848-.079 3.2033-.007 3.5835.005 4.8495.0608 1.169.0508 1.8053.2445 2.228.408.5608.216.96.4754 1.3816.895.4217.4194.6816.8176.9005 1.3787.1653.4217.3617 1.056.4169 2.2263.0602 1.2655.0739 1.645.0796 4.848.0058 3.203-.0055 3.5834-.061 4.848-.051 1.17-.245 1.8055-.408 2.2294-.216.5604-.4763.96-.8954 1.3814-.419.4215-.8181.6811-1.3783.9-.4224.1649-1.0577.3617-2.2262.4174-1.2656.0595-1.6448.072-4.8493.079-3.2045.007-3.5825-.006-4.848-.0608M16.953 5.5864A1.44 1.44 0 1 0 18.39 4.144a1.44 1.44 0 0 0-1.437 1.4424M5.8385 12.012c.0067 3.4032 2.7706 6.1557 6.173 6.1493 3.4026-.0065 6.157-2.7701 6.1506-6.1733-.0065-3.4032-2.771-6.1565-6.174-6.1498-3.403.0067-6.156 2.771-6.1496 6.1738M8 12.0077a4 4 0 1 1 4.008 3.9921A3.9996 3.9996 0 0 1 8 12.0077' },
    { name: 'Bluesky', tr: "Bluesky'da", href: 'https://bsky.app/profile/budgetella.app', d: 'M12 10.8c-1.087-2.114-4.046-6.053-6.798-7.995C2.566.944 1.561 1.266.902 1.565.139 1.908 0 3.08 0 3.768c0 .69.378 5.65.624 6.479.815 2.736 3.713 3.66 6.383 3.364.136-.02.275-.039.415-.056-.138.022-.276.04-.415.056-3.912.58-7.387 2.005-2.83 7.078 5.013 5.19 6.87-1.113 7.823-4.308.953 3.195 2.05 9.271 7.733 4.308 4.267-4.308 1.172-6.498-2.74-7.078a8.741 8.741 0 0 1-.415-.056c.14.017.279.036.415.056 2.67.297 5.568-.628 6.383-3.364.246-.828.624-5.79.624-6.478 0-.69-.139-1.861-.902-2.206-.659-.298-1.664-.62-4.3 1.24C16.046 4.748 13.087 8.687 12 10.8Z' },
    // { name: 'X', tr: "X'te", href: 'https://x.com/budgetella_app', d: 'M18.901 1.153h3.68l-8.04 9.19L24 22.846h-7.406l-5.8-7.584-6.638 7.584H.474l8.6-9.83L0 1.154h7.594l5.243 6.932ZM17.61 20.644h2.039L6.486 3.24H4.298Z' },
  ];
  const socialHTML = socials.map(s => {
    const label = isTR ? `Budgetella ${s.tr}` : `Budgetella on ${s.name}`;
    return `<a class="social-link" href="${s.href}" target="_blank" rel="me noopener" aria-label="${label}" title="${label}"><svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true" focusable="false"><path fill="currentColor" d="${s.d}"/></svg></a>`;
  }).join('');

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
        <nav class="footer-social" aria-label="${isTR ? 'Sosyal medya' : 'Social media'}">${socialHTML}</nav>
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
