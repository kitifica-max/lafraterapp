const CACHE_NAME = 'frater-app-v15';

const ASSETS_TO_CACHE = [
  '/',
  '/index.html',
  '/app.html',
  '/login.html',
  '/register.html',
  '/forgot-password.html',
  '/reset-password.html',
  '/explore.html',
  '/plan_detalles.html',
  '/profile.html',
  '/evento_detalle.html',
  '/ministerio_detalle.html',
  '/articulo_detalle.html',
  '/oracion.html',
  '/asistencia.html',
  '/ofrenda.html',
  '/ajustes.html',
  '/notificaciones.html',
  '/ayuda.html',
  '/crm-login.html',
  '/crm-dashboard.html',
  '/crm-eventos.html',
  '/crm-ministerios.html',
  '/crm-articulos.html',
  '/crm-plan.html',
  '/crm-oraciones.html',
  '/crm-asistencia.html',
  '/css/styles.css',
  '/css/login.css',
  '/css/explore.css',
  '/css/plan_detalles.css',
  '/css/profile.css',
  '/css/evento_detalle.css',
  '/css/ministerio_detalle.css',
  '/css/articulo_detalle.css',
  '/css/fab-menu.css',
  '/css/oracion.css',
  '/css/asistencia.css',
  '/css/ofrenda.css',
  '/css/ajustes.css',
  '/css/notificaciones.css',
  '/css/ayuda.css',
  '/css/crm.css',
  '/css/crm-login.css',
  '/js/supabase.js',
  '/js/auth-guard.js',
  '/js/fab-menu.js',
  '/js/crm-guard.js',
  '/img/LogoFrater_2.png',
  '/directorio.html',
  '/crm-servicios.html',
  '/crm-mensajes.html',
  '/crm-ofrenda.html',
  '/crm-usuarios.html',
  '/mensajes.html',
  '/cartelera.html',
  '/kairos-intro.html',
  '/kairos-leer.html'
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
  const url = new URL(event.request.url);

  // No interceptar peticiones a otros dominios (Supabase API, CDNs, etc.)
  if (url.origin !== self.location.origin) return;

  const isStaticAsset = /\.(png|jpg|jpeg|gif|svg|ico|woff2?|ttf)$/.test(url.pathname);

  if (isStaticAsset) {
    // Cache-first solo para imágenes/fuentes
    event.respondWith(
      caches.match(event.request).then(response => response || fetch(event.request).then(res => {
        const clone = res.clone();
        caches.open(CACHE_NAME).then(cache => cache.put(event.request, clone));
        return res;
      }))
    );
  } else {
    // Network-first para HTML/CSS/JS — siempre busca versión nueva
    event.respondWith(
      fetch(event.request)
        .then(res => {
          if (res.status === 200) {
            const clone = res.clone();
            caches.open(CACHE_NAME).then(cache => cache.put(event.request, clone));
          }
          return res;
        })
        .catch(() => caches.match(event.request))
    );
  }
});

self.addEventListener('push', event => {
  const data = event.data ? event.data.json() : { title: 'Frater', body: 'Tienes una nueva actualización.' };

  event.waitUntil(
    self.registration.showNotification(data.title, {
      body: data.body,
      icon: '/img/LogoFrater_1.png',
      badge: '/img/LogoFrater_1.png',
      vibrate: [100, 50, 100],
      data: { url: data.url || '/app.html' }
    })
  );
});

self.addEventListener('notificationclick', event => {
  event.notification.close();
  event.waitUntil(clients.openWindow(event.notification.data.url));
});
