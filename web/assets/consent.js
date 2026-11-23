// Budgetella · analytics consent.
// GA4 is the only non-essential thing on the site. Nothing is requested from
// Google and no cookie is set until the visitor accepts. Choice lives in
// localStorage; any element with [data-cookie-prefs] reopens the banner.
(function () {
  var GA_ID = 'G-93JNEYMKHT';
  var KEY = 'budgetella_consent';   // 'granted' | 'denied'
  var isTR = document.documentElement.lang === 'tr';
  var t = isTR ? {
    label: 'Çerez tercihleri',
    text: 'Siteyi kaç kişinin ziyaret ettiğini görmek için Google Analytics kullanmak istiyoruz. Kabul edersen analitik çerezleri yerleştirilir; reddedersen hiçbir şey yüklenmez.',
    more: 'Gizlilik Politikası',
    href: '/privacy-tr#cookies',
    accept: 'Kabul et',
    decline: 'Reddet'
  } : {
    label: 'Cookie preferences',
    text: 'We would like to use Google Analytics to see how many people visit the site. If you accept, analytics cookies are set; if you decline, nothing is loaded.',
    more: 'Privacy Policy',
    href: '/privacy#cookies',
    accept: 'Accept',
    decline: 'Decline'
  };

  function read() { try { return localStorage.getItem(KEY); } catch (e) { return null; } }
  function write(v) { try { localStorage.setItem(KEY, v); } catch (e) { /* private mode: ask again next visit */ } }

  var gaLoaded = false;
  function loadGA() {
    window['ga-disable-' + GA_ID] = false;
    if (gaLoaded) return;
    gaLoaded = true;
    window.dataLayer = window.dataLayer || [];
    window.gtag = function () { window.dataLayer.push(arguments); };
    window.gtag('js', new Date());
    window.gtag('config', GA_ID);
    var s = document.createElement('script');
    s.async = true;
    s.src = 'https://www.googletagmanager.com/gtag/js?id=' + GA_ID;
    document.head.appendChild(s);
  }

  function stopGA() {
    window['ga-disable-' + GA_ID] = true;
    // Remove GA cookies set under an earlier "accept".
    var host = location.hostname;
    var domains = ['', host, '.' + host, '.' + host.split('.').slice(-2).join('.')];
    document.cookie.split(';').forEach(function (c) {
      var name = c.split('=')[0].trim();
      if (name !== '_ga' && name.indexOf('_ga_') !== 0) return;
      domains.forEach(function (d) {
        document.cookie = name + '=; Max-Age=0; path=/' + (d ? '; domain=' + d : '');
      });
    });
  }

  var banner = null;
  var returnFocus = null;

  function close() {
    if (!banner) return;
    banner.remove();
    banner = null;
    if (returnFocus && document.contains(returnFocus)) returnFocus.focus();
    returnFocus = null;
  }

  function choose(value) {
    write(value);
    if (value === 'granted') loadGA(); else stopGA();
    close();
  }

  function open(opener) {
    if (banner) { banner.focus(); return; }
    returnFocus = opener || null;
    banner = document.createElement('section');
    banner.className = 'consent';
    banner.setAttribute('role', 'region');
    banner.setAttribute('aria-label', t.label);
    banner.tabIndex = -1;
    banner.innerHTML =
      '<p class="consent-text">' + t.text + ' <a href="' + t.href + '">' + t.more + '</a></p>' +
      '<div class="consent-actions">' +
        '<button type="button" class="consent-btn" data-consent="denied">' + t.decline + '</button>' +
        '<button type="button" class="consent-btn" data-consent="granted">' + t.accept + '</button>' +
      '</div>';
    banner.addEventListener('click', function (e) {
      var b = e.target.closest('[data-consent]');
      if (b) choose(b.getAttribute('data-consent'));
    });
    banner.addEventListener('keydown', function (e) {
      // Escape only dismisses when a choice already exists (reopened from the footer).
      if (e.key === 'Escape' && read()) close();
    });
    document.body.appendChild(banner);
    // Only move focus when the visitor asked for the banner; never steal it on page load.
    if (opener) banner.focus();
  }

  var choice = read();
  if (choice === 'granted') loadGA();

  function init() {
    if (!choice) open(null);
    document.addEventListener('click', function (e) {
      var el = e.target.closest('[data-cookie-prefs]');
      if (!el) return;
      e.preventDefault();
      open(el);
    });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
  else init();
})();
