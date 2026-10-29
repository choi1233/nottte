// 앱 파일만 캐시해요. 사진과 기록은 IndexedDB에 따로 있어서, 앱을 업데이트해도 지워지지 않아요.
// 업데이트를 올릴 때 VERSION 숫자만 올리면 돼요.
const VERSION = "nottte-v5";
const SHELL = ["./", "index.html", "manifest.webmanifest", "fonts/PretendardVariable.woff2",
  "icons/logo-mask.png", "icons/icon-192.png", "icons/icon-512.png", "icons/apple-touch-icon.png"];

self.addEventListener("install", (e) => { e.waitUntil(caches.open(VERSION).then((c) => c.addAll(SHELL))); self.skipWaiting(); });
self.addEventListener("activate", (e) => {
  e.waitUntil(caches.keys().then((ks) => Promise.all(ks.filter((k) => k !== VERSION).map((k) => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener("fetch", (e) => {
  const req = e.request;
  if (req.method !== "GET" || new URL(req.url).origin !== location.origin) return;
  if (req.mode === "navigate") {
    // 화면은 인터넷이 되면 항상 최신 버전을, 안 되면 저장해둔 버전을 보여줘요.
    e.respondWith(fetch(req).then((r) => { const copy = r.clone(); caches.open(VERSION).then((c) => c.put("index.html", copy)); return r; })
      .catch(() => caches.match("index.html")));
    return;
  }
  e.respondWith(caches.match(req).then((hit) => hit || fetch(req)));
});
