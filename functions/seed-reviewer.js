// seed-reviewer.js — App Store reviewer hesabına demo data yükler
// Çalıştır: cd functions && node seed-reviewer.js

const PROJECT_ID = "budgetella-d1d41";
const API_KEY    = "AIzaSyBgS_o3IYOxSeGbgUA3QVkY-LLQD25m3gE";
const EMAIL      = "appreviewer@budgetella.app";
const PASSWORD   = "Review@Budgetella2026";

// ── HTTP helpers ─────────────────────────────────────────────────────────────

function post(url, body) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(body);
    const u = new URL(url);
    const req = require("https").request(
      { hostname: u.hostname, path: u.pathname + u.search, method: "POST",
        headers: { "Content-Type": "application/json", "Content-Length": Buffer.byteLength(data) } },
      (res) => {
        let raw = "";
        res.on("data", (c) => (raw += c));
        res.on("end", () => {
          try { resolve(JSON.parse(raw)); }
          catch (e) { resolve({ _raw: raw }); }
        });
      }
    );
    req.on("error", reject);
    req.write(data);
    req.end();
  });
}

function firestore(method, path, body, token) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : undefined;
    const req = require("https").request(
      { hostname: "firestore.googleapis.com", path,
        method, headers: { "Authorization": `Bearer ${token}`,
          "Content-Type": "application/json",
          ...(data ? { "Content-Length": Buffer.byteLength(data) } : {}) } },
      (res) => {
        let raw = "";
        res.on("data", (c) => (raw += c));
        res.on("end", () => {
          try { resolve(JSON.parse(raw)); }
          catch (e) { resolve({ _raw: raw }); }
        });
      }
    );
    req.on("error", reject);
    if (data) req.write(data);
    req.end();
  });
}

// ── UUID & Firestore value helpers ───────────────────────────────────────────

function uuid() {
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    return (c === "x" ? r : (r & 0x3) | 0x8).toString(16);
  });
}

function tsValue(year, month, day) {
  const d = new Date(year, month - 1, day, 12, 0, 0);
  return { timestampValue: d.toISOString() };
}

function nowValue() {
  return { timestampValue: new Date().toISOString() };
}

function str(v)  { return { stringValue: v }; }
function num(v)  { return { doubleValue: v }; }
function bool(v) { return { booleanValue: v }; }
function int(v)  { return { integerValue: String(v) }; }

function doc(fields) { return { fields }; }

// ── Data ─────────────────────────────────────────────────────────────────────

const CATEGORIES = [
  { slug: "salary",         name: "Maaş",         type: "income",  icon: "banknote",                           color: "#22c55e", order: 0 },
  { slug: "freelance",      name: "Freelance",     type: "income",  icon: "briefcase",                          color: "#10b981", order: 1 },
  { slug: "investments",    name: "Yatırım",       type: "income",  icon: "chart.line.uptrend.xyaxis",          color: "#06b6d4", order: 2 },
  { slug: "gifts",          name: "Hediyeler",     type: "income",  icon: "gift",                               color: "#ec4899", order: 3 },
  { slug: "productSale",    name: "Ürün Satışı",   type: "income",  icon: "shippingbox.fill",                   color: "#f59e0b", order: 4 },
  { slug: "loan",           name: "Borç Para",     type: "income",  icon: "arrow.left.arrow.right.circle.fill", color: "#8b5cf6", order: 5 },
  { slug: "food",           name: "Yiyecek",       type: "expense", icon: "fork.knife",                         color: "#f59e0b", order: 6 },
  { slug: "transportation", name: "Ulaşım",        type: "expense", icon: "car.fill",                           color: "#3b82f6", order: 7 },
  { slug: "housing",        name: "Konut",         type: "expense", icon: "house.fill",                         color: "#8b5cf6", order: 8 },
  { slug: "bills",          name: "Faturalar",     type: "expense", icon: "doc.text",                           color: "#ef4444", order: 9 },
  { slug: "healthcare",     name: "Sağlık",        type: "expense", icon: "cross.case",                         color: "#dc2626", order: 10 },
  { slug: "shopping",       name: "Alışveriş",     type: "expense", icon: "bag.fill",                           color: "#a855f7", order: 11 },
  { slug: "entertainment",  name: "Eğlence",       type: "expense", icon: "tv",                                 color: "#f43f5e", order: 12 },
  { slug: "education",      name: "Eğitim",        type: "expense", icon: "book.fill",                          color: "#0ea5e9", order: 13 },
  { slug: "other",          name: "Diğer",         type: "expense", icon: "tag",                                color: "#94a3b8", order: 14 },
];

const TRANSACTIONS = [
  { type: "income",  amount: 45000, note: "Maaş - Nisan 2026",    slug: "salary",         y: 2026, m: 4, d: 1  },
  { type: "income",  amount: 8500,  note: "Freelance UI projesi",  slug: "freelance",      y: 2026, m: 4, d: 7  },
  { type: "expense", amount: 22000, note: "Kira - Nisan",          slug: "housing",        y: 2026, m: 4, d: 2  },
  { type: "expense", amount: 1850,  note: "Shell benzin",          slug: "transportation", y: 2026, m: 4, d: 3  },
  { type: "expense", amount: 2340,  note: "Migros alışveriş",      slug: "food",           y: 2026, m: 4, d: 5  },
  { type: "expense", amount: 750,   note: "Vodafone fatura",        slug: "bills",          y: 2026, m: 4, d: 6  },
  { type: "expense", amount: 890,   note: "BİM market",            slug: "food",           y: 2026, m: 4, d: 8  },
  { type: "expense", amount: 320,   note: "Starbucks",              slug: "food",           y: 2026, m: 4, d: 9  },
  { type: "expense", amount: 450,   note: "Uber",                   slug: "transportation", y: 2026, m: 4, d: 10 },
  { type: "expense", amount: 255,   note: "Netflix abonelik",       slug: "bills",          y: 2026, m: 4, d: 12 },
  { type: "expense", amount: 475,   note: "Yemeksepeti",            slug: "food",           y: 2026, m: 4, d: 13 },
  { type: "expense", amount: 1280,  note: "Trendyol alışveriş",    slug: "shopping",       y: 2026, m: 4, d: 15 },
  { type: "expense", amount: 640,   note: "A101 market",            slug: "food",           y: 2026, m: 4, d: 17 },
  { type: "expense", amount: 880,   note: "İGDAŞ doğalgaz",         slug: "bills",          y: 2026, m: 4, d: 18 },
  { type: "expense", amount: 350,   note: "Cinemaximum",            slug: "entertainment",  y: 2026, m: 4, d: 20 },
  { type: "expense", amount: 1650,  note: "Opet benzin",            slug: "transportation", y: 2026, m: 4, d: 22 },
  { type: "expense", amount: 3200,  note: "H&M alışveriş",         slug: "shopping",       y: 2026, m: 4, d: 24 },
  { type: "expense", amount: 420,   note: "Udemy kurs",             slug: "education",      y: 2026, m: 4, d: 25 },
  { type: "expense", amount: 560,   note: "Getir market",           slug: "food",           y: 2026, m: 4, d: 27 },
  { type: "expense", amount: 280,   note: "HGS otoyol geçiş",      slug: "transportation", y: 2026, m: 4, d: 29 },
  { type: "income",  amount: 45000, note: "Maaş - Mayıs 2026",     slug: "salary",         y: 2026, m: 5, d: 1  },
  { type: "expense", amount: 1150,  note: "Migros alışveriş",      slug: "food",           y: 2026, m: 5, d: 2  },
  { type: "expense", amount: 490,   note: "Getir market",           slug: "food",           y: 2026, m: 5, d: 3  },
];

// ── Main ─────────────────────────────────────────────────────────────────────

async function seed() {
  // 1. Sign in
  console.log(`\n→ Signing in as ${EMAIL}...`);
  const authResp = await post(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`,
    { email: EMAIL, password: PASSWORD, returnSecureToken: true }
  );
  if (!authResp.idToken) {
    console.error("❌ Auth failed:", authResp.error || authResp);
    process.exit(1);
  }
  const TOKEN = authResp.idToken;
  const UID   = authResp.localId;
  console.log(`  ✓ Signed in — UID: ${UID}`);

  const BASE = `/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${UID}`;

  // 2. Categories
  console.log(`\n→ Writing ${CATEGORIES.length} categories...`);
  for (const cat of CATEGORIES) {
    const id = uuid();
    const path = `${BASE}/categories/${id}`;
    const body = doc({
      id:        str(id),
      userId:    str(UID),
      name:      str(cat.name),
      slug:      str(cat.slug),
      type:      str(cat.type),
      iconName:  str(cat.icon),
      colorHex:  str(cat.color),
      isDefault: bool(true),
      sortOrder: int(cat.order),
    });
    const res = await firestore("PATCH", path, body, TOKEN);
    if (res.error) { console.error(`  ❌ category ${cat.slug}:`, res.error); }
    else           { process.stdout.write("."); }
  }
  console.log("\n  ✓ Categories done");

  // 3. Transactions
  console.log(`\n→ Writing ${TRANSACTIONS.length} transactions...`);
  for (const tx of TRANSACTIONS) {
    const id = uuid();
    const path = `${BASE}/transactions/${id}`;
    const body = doc({
      id:                str(id),
      userId:            str(UID),
      type:              str(tx.type),
      amount:            num(tx.amount),
      currency:          str("TRY"),
      note:              str(tx.note),
      categorySlug:      str(tx.slug),
      date:              tsValue(tx.y, tx.m, tx.d),
      status:            str("completed"),
      isRecurring:       bool(false),
      recurringInterval: str(""),
      createdAt:         nowValue(),
      updatedAt:         nowValue(),
    });
    const res = await firestore("PATCH", path, body, TOKEN);
    if (res.error) { console.error(`  ❌ tx ${tx.note}:`, res.error); }
    else           { process.stdout.write("."); }
  }
  console.log("\n  ✓ Transactions done");

  console.log("\n✅ appreviewer@budgetella.app is ready for App Store review.\n");
}

seed().catch((err) => { console.error("❌", err); process.exit(1); });
