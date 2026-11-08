/* Mappa Viaggi: fa funzionare la pagina e i pezzi di mappa già visti anche senza internet. */
// Nomi con prefisso "mappa-": su robb2000fred.github.io possono convivere altre app, e non vanno toccate le loro cache.
const APP = "mappa-app-v3", TILES = "mappa-tiles-v1", LEGACY = ["app-v1", "app-v2", "tiles-v1"];
const FILES = ["./", "./index.html", "./manifest.webmanifest", "./vendor/leaflet.min.js", "./vendor/leaflet.min.css", "./fonts/poppins.css",
  ...["400", "500", "600", "700"].flatMap(w => [`./fonts/poppins-${w}-latin.woff2`, `./fonts/poppins-${w}-latin-ext.woff2`]),
  "./icons/icon-180.png", "./icons/icon-192.png", "./icons/icon-512.png"];

self.addEventListener("install", e => { e.waitUntil(caches.open(APP).then(c => c.addAll(FILES)).then(() => self.skipWaiting())); });
self.addEventListener("activate", e => {
  e.waitUntil((async () => {
    // I tasselli già salvati nella vecchia cache "tiles-v1" passano nella nuova, così non si perdono.
    let migrated = true;
    if (await caches.has("tiles-v1")) {
      try { const old = await caches.open("tiles-v1"), nw = await caches.open(TILES);
        for (const k of await old.keys()) { if (!(await nw.match(k))) { const r = await old.match(k); if (r) await nw.put(k, r); } } }
      catch { migrated = false; } // spazio finito o errore: la vecchia cache resta, si riprova alla prossima attivazione
    }
    const ks = await caches.keys();
    await Promise.all(ks.filter(k => (k.startsWith("mappa-") || LEGACY.includes(k)) && k !== APP && k !== TILES && (migrated || k !== "tiles-v1")).map(k => caches.delete(k)));
    await self.clients.claim();
  })());
});
self.addEventListener("fetch", e => {
  const u = new URL(e.request.url);
  if (u.hostname === "tile.openstreetmap.org") {
    // Pezzi di mappa: prima la memoria, poi la rete (e ogni pezzo visto resta in memoria).
    e.respondWith(caches.open(TILES).then(async c => {
      const hit = await c.match(u.href); if (hit) return hit;
      try { const r = await fetch(e.request); if (r.ok || r.type === "opaque") { const copy = r.clone(); e.waitUntil(c.put(u.href, copy).catch(() => {})); } return r; }
      catch { return Response.error(); }
    }));
    return;
  }
  if (u.origin === location.origin && e.request.method === "GET") {
    // File della pagina: prima la rete (così gli aggiornamenti arrivano), senza rete la copia salvata.
    e.respondWith(fetch(e.request).then(r => { if (r.ok) { const copy = r.clone(); e.waitUntil(caches.open(APP).then(c => c.put(e.request, copy)).catch(() => {})); } return r; })
      .catch(() => caches.match(e.request, { ignoreSearch: true }).then(h => h || (e.request.mode === "navigate" ? caches.match("./index.html") : Response.error()))));
  }
});
