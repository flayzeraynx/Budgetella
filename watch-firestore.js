#!/usr/bin/env node
/**
 * Budgetella — Firestore FCM Token Watcher
 *
 * FCM token Firestore'a yazılana kadar 3 saniyede bir kontrol eder.
 * Token görününce push gönderir.
 *
 * Kullanım:
 *   node watch-firestore.js
 */

const fs    = require('fs');
const https = require('https');
const os    = require('os');
const { execSync } = require('child_process');

const PROJECT_ID = 'budgetella-d1d41';
const USER_UID   = '7n48wY1HdMWD8ZdX00hzqwZAcsb2';
const POLL_MS    = 3000;

function httpsGet(url, token) {
  return new Promise((resolve, reject) => {
    const req = https.request(url, {
      method: 'GET',
      headers: { Authorization: `Bearer ${token}`, Accept: 'application/json' },
    }, res => {
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
    const req = https.request({
      hostname: urlObj.hostname,
      path:     urlObj.pathname + urlObj.search,
      method:   'POST',
      headers: {
        Authorization:  `Bearer ${token}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data),
      },
    }, res => {
      let body = '';
      res.on('data', d => (body += d));
      res.on('end', () => resolve({ status: res.statusCode, body: JSON.parse(body) }));
    });
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

function getAccessToken() {
  const configPath = `${os.homedir()}/.config/configstore/firebase-tools.json`;
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const tokens = config.tokens || {};
  const expiresAt = tokens.expires_at || 0;

  if (Date.now() >= expiresAt - 60_000) {
    // Force refresh via Firebase CLI
    try { execSync('firebase projects:list --project budgetella-d1d41', { stdio: 'pipe' }); } catch (_) {}
    const fresh = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    return fresh.tokens?.access_token;
  }
  return tokens.access_token;
}

async function sendPush(fcmToken, accessToken) {
  const resp = await httpsPost(
    `https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`,
    accessToken,
    {
      message: {
        token: fcmToken,
        notification: {
          title: '🎉 Budgetella Push Çalışıyor!',
          body:  'FCM entegrasyonu başarıyla kuruldu.',
        },
        data: {
          kind:     'systemMessage',
          deepLink: 'budgetella://stats',
        },
        apns: { payload: { aps: { sound: 'default', badge: 1 } } },
      },
    }
  );

  if (resp.status === 200) {
    console.log('\n✅ Push gönderildi!');
    console.log(`   Message ID: ${resp.body.name}`);
    console.log('   Cihazında bildirim görünmeli.');
  } else {
    console.error('\n❌ FCM hatası:', JSON.stringify(resp.body, null, 2));
  }
}

async function poll() {
  const accessToken = getAccessToken();
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${USER_UID}`;
  const resp = await httpsGet(url, accessToken);

  if (resp.status === 200) {
    const fcmToken = resp.body.fields?.fcmToken?.stringValue;
    if (fcmToken) {
      console.log(`\n✓ FCM token Firestore'da bulundu: ${fcmToken.slice(0, 24)}...`);
      await sendPush(fcmToken, accessToken);
      return true; // done
    } else {
      process.stdout.write('.');
    }
  } else if (resp.status === 404) {
    process.stdout.write('○'); // document doesn't exist yet
  } else {
    process.stdout.write('?');
  }
  return false;
}

async function main() {
  console.log('👀 Firestore izleniyor — uygulamada bildirim toggle\'ını kapat/aç...');
  console.log('   (Ctrl+C ile çıkabilirsin)\n');
  process.stdout.write('Kontroller: ');

  let done = false;
  while (!done) {
    try {
      done = await poll();
    } catch (e) {
      process.stdout.write('!');
    }
    if (!done) await new Promise(r => setTimeout(r, POLL_MS));
  }
}

main().catch(err => {
  console.error('\n❌ Hata:', err.message);
  process.exit(1);
});
