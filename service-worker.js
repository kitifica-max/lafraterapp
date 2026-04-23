const CACHE_NAME = 'frater-app-v2';

const ASSETS_TO_CACHE = [
  '/',
  '/index.html',
  '/login.html',
  '/explore.html',
  '/plan_detalles.html',
  '/profile.html',
  '/evento_detalle.html',
  '/ministerio_detalle.html',
  '/articulo_detalle.html',
  '/css/styles.css',
  '/css/login.css',
  '/css/explore.css',
  '/css/plan_detalles.css',
  '/css/profile.css',
  '/css/evento_detalle.css',
  '/css/ministerio_detalle.css',
  '/css/articulo_detalle.css',
  '/js/supabase.js',
  '/js/auth-guard.js',
  '/img/LogoFrater_1.png'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(ASSETS_TO_CACHE))
  );
  self.skipWaiting();
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(
        keys.filter(key => key !== CACHE_NAME).map(key => caches.delete(key))
      )
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request).then(response => response || fetch(event.request))
  );
});

self.addEventListener('push', event => {
  const data = event.data ? event.data.json() : { title: 'Frater', body: 'Tienes una nueva actualización.' };

  event.waitUntil(
    self.registration.showNotification(data.title, {
      body: data.body,
      icon: '/img/LogoFrater_1.png',
      badge: '/img/LogoFrater_1.png',
      vibrate: [100, 50, 100],
      data: { url: data.url || '/index.html' }
    })
  );
});

self.addEventListener('notificationclick', event => {
  event.notification.close();
  event.waitUntil(clients.openWindow(event.notification.data.url));
});
