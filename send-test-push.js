#!/usr/bin/env node
/**
 * Budgetella — FCM Test Push Gönderici
 *
 * Kullanım:
 *   cd /Users/flayzeraynx/Development/Budgetella
 *   node send-test-push.js
 *
 * Ön koşul:
 *   App cihazda çalışmış olmalı — FCM token Firestore'a otomatik yazılır.
 *   firebase login ile giriş yapılmış olmalı (zaten yapılmış).
 */

const fs             = require('fs');
const https          = require('https');
const os             = require('os');
const { execSync }   = require('child_process');

const PROJECT_ID = 'budgetella-d1d41';
const USER_UID   = '7n48wY1HdMWD8ZdX00hzqwZAcsb2';

// ─── Helpers ──────────────────────────────────────────────────────────────────

function httpsGet(url, token) {
  return new Promise((resolve, reject) => {
    const options = {
      method: 'GET',
      headers: { Authorization: `Bearer ${token}`, Accept: 'application/json' },
    };
    const req = https.request(url, options, res => {
      let body = '';
      res.on('data', d => (body += d));
      res.on('end', () => resolve({ status: res.statusCode, body: JSON.parse(body) }));
    });
    req.on('error', reject);
    req.end();
  });
}

function httpsPost(url, token, payload) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(payload);
    const urlObj = new URL(url);
    const options = {
      hostname: urlObj.hostname,
      path:     urlObj.pathname + urlObj.search,
      method:   'POST',
      headers: {
        Authorization:  `Bearer ${token}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data),
      },
    };
    const req = https.request(options, res => {
      let body = '';
      res.on('data', d => (body += d));
      res.on('end', () => resolve({ status: res.statusCode, body: JSON.parse(body) }));
    });
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

function refreshViaFirebaseCLI() {
  // Let the Firebase CLI do the token refresh — it knows its own OAuth credentials
  try {
    execSync('firebase projects:list --project budgetella-d1d41', { stdio: 'pipe' });
  } catch (_) {
    // If it fails for other reasons we'll catch the 401 later
  }
  const config = JSON.parse(fs.readFileSync(`${os.homedir()}/.config/configstore/firebase-tools.json`, 'utf8'));
  return config.tokens?.access_token;
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  // 1. Load Firebase CLI credentials
  const configPath = `${os.homedir()}/.config/configstore/firebase-tools.json`;
  if (!fs.existsSync(configPath)) {
    console.error('❌ Firebase CLI config bulunamadı. Önce: firebase login');
    process.exit(1);
  }

  const config       = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const tokens       = config.tokens || {};
  let   accessToken = tokens.access_token;
  const expiresAt   = tokens.expires_at || 0;

  // 2. Refresh token if needed
  if (Date.now() >= expiresAt - 60_000) {
    console.log('[0/3] Access token süresi dolmuş, Firebase CLI ile yenileniyor...');
    accessToken = refreshViaFirebaseCLI();
    if (!accessToken) {
      console.error('❌ Token yenilenemedi.');
      console.error('   → firebase login ile yeniden giriş yap.');
      process.exit(1);
    }
    console.log('[0/3] Token yenilendi ✓');
  }

  // 3. Read FCM token from Firestore
  console.log(`[1/3] Firestore'dan FCM token okunuyor (uid: ${USER_UID})...`);
  const firestoreUrl = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${USER_UID}`;
  const fsResp = await httpsGet(firestoreUrl, accessToken);

  if (fsResp.status === 404) {
    console.error('❌ Kullanıcı belgesi bulunamadı (404).');
    console.error('   → Uygulamayı cihazda bir kez aç, bildirim iznini ver, sonra tekrar çalıştır.');
    process.exit(1);
  }

  if (fsResp.status !== 200) {
    console.error(`❌ Firestore hatası (${fsResp.status}):`, JSON.stringify(fsResp.body));
    process.exit(1);
  }

  const fields   = fsResp.body.fields || {};
  const fcmToken = fields.fcmToken?.stringValue;

  if (!fcmToken) {
    console.error('❌ fcmToken alanı Firestore\'da yok.');
    console.error('   → Uygulama bildirim iznini onayladığında yazılır. Bir kez kapat-aç.');
    process.exit(1);
  }

  console.log(`[2/3] Token alındı: ${fcmToken.slice(0, 24)}...`);

  // 4. Send FCM push via HTTP v1 API
  console.log('[3/3] Test push gönderiliyor...\n');

  const fcmUrl = `https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`;
  const fcmResp = await httpsPost(fcmUrl, accessToken, {
    message: {
      token: fcmToken,
      notification: {
        title: '🎉 Budgetella Push Çalışıyor!',
        body:  'FCM entegrasyonu başarıyla kuruldu. Bu bir test mesajıdır.',
      },
      data: {
        kind:     'systemMessage',
        deepLink: 'budgetella://stats',
      },
      apns: {
        payload: {
          aps: { sound: 'default', badge: 1 },
        },
      },
    },
  });

  if (fcmResp.status === 200) {
    console.log('✅ Push başarıyla gönderildi!');
    console.log(`   Message ID: ${fcmResp.body.name}`);
    console.log('\n   Cihazında bildirim görünmeli.');
    console.log("   Tıklarsan budgetella://stats deep link'i tetikler → Stats sekmesi açılır.");
  } else {
    console.error(`❌ FCM hatası (${fcmResp.status}):`, JSON.stringify(fcmResp.body, null, 2));
    if (fcmResp.status === 401) {
      console.error('\n   → Access token geçersiz. firebase login ile yeniden giriş yap.');
    } else if (fcmResp.status === 403) {
      console.error('\n   → FCM API erişim hatası. Firebase Console → Cloud Messaging API etkinleştirilmiş mi?');
    }
    process.exit(1);
  }
}

main().catch(err => {
  console.error('\n❌ Beklenmedik hata:', err.message);
  process.exit(1);
});
