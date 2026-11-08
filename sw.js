/* Mappa Viaggi: fa funzionare la pagina e i pezzi di mappa già visti anche senza internet. */
const APP = "app-v2", TILES = "tiles-v1";
const FILES = ["./", "./index.html", "./manifest.webmanifest", "./vendor/leaflet.min.js", "./vendor/leaflet.min.css", "./fonts/poppins.css",
  ...["400", "500", "600", "700"].flatMap(w => [`./fonts/poppins-${w}-latin.woff2`, `./fonts/poppins-${w}-latin-ext.woff2`]),
  "./icons/icon-180.png", "./icons/icon-192.png", "./icons/icon-512.png"];

self.addEventListener("install", e => { e.waitUntil(caches.open(APP).then(c => c.addAll(FILES)).then(() => self.skipWaiting())); });
self.addEventListener("activate", e => {
  e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== APP && k !== TILES).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener("fetch", e => {
  const u = new URL(e.request.url);
  if (u.hostname === "tile.openstreetmap.org") {
    // Pezzi di mappa: prima la memoria, poi la rete (e ogni pezzo visto resta in memoria).
    e.respondWith(caches.open(TILES).then(async c => {
      const hit = await c.match(u.href); if (hit) return hit;
      try { const r = await fetch(e.request); if (r.ok || r.type === "opaque") c.put(u.href, r.clone()); return r; }
      catch { return Response.error(); }
    }));
    return;
  }
  if (u.origin === location.origin && e.request.method === "GET") {
    // File della pagina: prima la rete (così gli aggiornamenti arrivano), senza rete la copia salvata.
    e.respondWith(fetch(e.request).then(r => { if (r.ok) caches.open(APP).then(c => c.put(e.request, r.clone())); return r; })
      .catch(() => caches.match(e.request, { ignoreSearch: true }).then(h => h || (e.request.mode === "navigate" ? caches.match("./index.html") : Response.error()))));
  }
});
