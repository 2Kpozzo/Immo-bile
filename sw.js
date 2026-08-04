// Service Worker Immo-bile — met en cache la coquille de l'app (HTML, manifest, icônes)
// pour un chargement instantané, y compris hors connexion. Les appels à Supabase
// (données) ne sont volontairement PAS mis en cache : ils doivent toujours être frais.

const CACHE_NAME = 'immobile-shell-v6'; // ⚠️ incrémentez ce numéro à chaque mise à jour de l'app
const APP_SHELL = [
  './',
  './index.html',
  './manifest.json',
  './icon-192.png',
  './icon-512.png'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL)).catch(() => {})
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // On ne met JAMAIS en cache les appels vers Supabase (données toujours fraîches)
  if (url.hostname.endsWith('supabase.co')) {
    return; // laisse passer directement au réseau
  }

  // Pour le reste (coquille de l'app), stratégie "cache d'abord, réseau en secours"
  event.respondWith(
    caches.match(event.request).then((cached) => {
      if (cached) return cached;
      return fetch(event.request).then((resp) => {
        // met en cache les nouvelles ressources statiques récupérées avec succès
        if (resp && resp.status === 200 && event.request.method === 'GET') {
          const respClone = resp.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, respClone));
        }
        return resp;
      }).catch(() => cached);
    })
  );
});
