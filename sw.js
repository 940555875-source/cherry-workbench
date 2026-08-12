// amber的工作台 Service Worker v10
// Strategy: HTML uses network-first so updates are immediately picked up;
// static assets use cache-first for fast reload.

const VERSION = 'amber-workbench-v10';
const STATIC_CACHE = VERSION + '-static';

// Use relative paths so this works on both domain root and GitHub Pages sub-paths.
const APP_SHELL = [
  './',
  './index.html',
  './manifest.json',
  './icons/icon-48x48.png',
  './icons/icon-72x72.png',
  './icons/icon-96x96.png',
  './icons/icon-144x144.png',
  './icons/icon-168x168.png',
  './icons/icon-192x192.png',
  './icons/icon-512x512.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(STATIC_CACHE).then((cache) => cache.addAll(APP_SHELL))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((names) =>
      Promise.all(
        names
          .filter((n) => n !== STATIC_CACHE)
          .map((n) => caches.delete(n))
      )
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;
  const url = new URL(event.request.url);

  // Supabase: never cache
  if (url.hostname.includes('supabase.co') || url.hostname.includes('supabase.in')) {
    event.respondWith(fetch(event.request).catch(() => new Response('', { status: 503 })));
    return;
  }

  // Navigation (HTML): network-first so users always get the latest code
  if (event.request.mode === 'navigate' || event.request.destination === 'document') {
    event.respondWith(networkFirst(event.request));
    return;
  }

  // Other same-origin assets: cache-first
  if (url.origin === self.location.origin) {
    event.respondWith(cacheFirst(event.request));
  }
});

async function cacheFirst(request) {
  const cached = await caches.match(request);
  if (cached) return cached;
  try {
    const res = await fetch(request);
    if (res.ok) {
      const c = await caches.open(STATIC_CACHE);
      c.put(request, res.clone());
    }
    return res;
  } catch (e) {
    return new Response('offline', { status: 503 });
  }
}

async function networkFirst(request) {
  try {
    const res = await fetch(request);
    if (res.ok) {
      const c = await caches.open(STATIC_CACHE);
      c.put(request, res.clone());
    }
    return res;
  } catch (e) {
    const cached = await caches.match(request) || await caches.match('./index.html');
    return cached || new Response('offline', { status: 503 });
  }
}
