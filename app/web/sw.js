/* Service worker de Aletheia.
 *
 * Dos cachés:
 *  - aletheia-shell: el shell de la app (Flutter, wasm, iconos).
 *  - aletheia-mods:  el catálogo estático de aletheia-mods.
 *
 * El catálogo se sirve desde otro origen con CORS. Las URLs de contenido
 * llevan `?v=<versión>` cuando la app ya leyó mods.json; las respuestas
 * versionadas se sirven primero desde caché. mods.json se consulta a la red
 * para detectar actualizaciones y, si no hay red, se usa la copia guardada.
 */
'use strict';

importScripts('sw-manifest.js');

const SHELL_CACHE = 'aletheia-shell-v2';
const MODS_CACHE = 'aletheia-mods-v1';
const MODS_PATH = '/aletheia-mods/';
const SHELL_ASSETS = self.ALETHEIA_SHELL_ASSETS || [];

async function precacheShell() {
  const cache = await caches.open(SHELL_CACHE);
  await Promise.allSettled(
    SHELL_ASSETS.map(async (asset) => {
      try {
        const url = new URL(asset, self.registration.scope).href;
        // `no-cache` revalida con ETag: evita conservar un shell viejo tras
        // un despliegue sin volver a descargar lo que no cambió.
        const response = await fetch(url, { cache: 'no-cache' });
        if (response.ok) await cache.put(url, response);
      } catch (_) {
        // Un archivo opcional no debe impedir la instalación.
      }
    }),
  );
}

self.addEventListener('install', (event) => {
  // Activar de inmediato. La precarga del shell se hace en `activate`, así el
  // worker controla la página en segundos y puede cachear también el catálogo
  // mientras el navegador sigue descargando el shell en segundo plano.
  event.waitUntil(self.skipWaiting());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const names = await caches.keys();
    await Promise.all(
      names
        // Al cambiar la versión del worker se renueva el shell completo. El
        // catálogo se conserva: sus URLs ya llevan la versión de mods.json.
        .filter((name) => name.startsWith('aletheia-') && name !== MODS_CACHE)
        .map((name) => caches.delete(name)),
    );
    await self.clients.claim();
    await precacheShell();
  })());
});

function isVersioned(url) {
  return url.searchParams.has('v');
}

async function put(cacheName, request, response) {
  if (!response || !response.ok) return;
  try {
    const cache = await caches.open(cacheName);
    await cache.put(request, response.clone());
  } catch (_) {
    // Cuota agotada o respuesta no cacheable: la app sigue funcionando.
  }
}

async function networkFirst(request, cacheName) {
  try {
    const response = await fetch(request);
    if (response.ok) await put(cacheName, request, response);
    return response;
  } catch (_) {
    let cached = await caches.match(request, {
      ignoreVary: true,
      ignoreSearch: cacheName === SHELL_CACHE,
    });
    if (!cached && request.mode === 'navigate') {
      // Respaldo para navegaciones offline a una ruta sin entrada exacta.
      const index = new URL('index.html', self.registration.scope).href;
      cached = await caches.match(index, {
        ignoreVary: true,
        ignoreSearch: true,
      });
    }
    if (cached) return cached;
    throw _;
  }
}

async function cacheFirst(request, cacheName) {
  const cached = await caches.match(request, {
    ignoreVary: true,
    ignoreSearch: cacheName === SHELL_CACHE,
  });
  if (cached) return cached;
  const response = await fetch(request);
  if (response.ok) await put(cacheName, request, response);
  return response;
}

async function staleWhileRevalidate(request, cacheName) {
  const cached = await caches.match(request, {
    ignoreVary: true,
    ignoreSearch: cacheName === SHELL_CACHE,
  });
  if (cached) {
    // La actualización sigue en segundo plano, sin bloquear la lectura.
    fetch(request)
      .then((response) => {
        if (response.ok) return put(cacheName, request, response);
      })
      .catch(() => {});
    return cached;
  }
  const response = await fetch(request);
  if (response.ok) await put(cacheName, request, response);
  return response;
}

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;
  // No cachear descargas parciales.
  if (request.headers.has('Range')) return;

  const url = new URL(request.url);
  const scope = new URL(self.registration.scope).pathname;

  if (url.pathname.startsWith(MODS_PATH)) {
    if (url.pathname.endsWith('/mods.json')) {
      event.respondWith(networkFirst(request, MODS_CACHE));
    } else if (isVersioned(url) || url.pathname.endsWith('.gz')) {
      event.respondWith(cacheFirst(request, MODS_CACHE));
    } else {
      event.respondWith(staleWhileRevalidate(request, MODS_CACHE));
    }
    return;
  }

  if (url.origin === self.location.origin && url.pathname.startsWith(scope)) {
    if (request.mode === 'navigate' || url.pathname.endsWith('/index.html')) {
      event.respondWith(networkFirst(request, SHELL_CACHE));
    } else {
      event.respondWith(staleWhileRevalidate(request, SHELL_CACHE));
    }
  }
});
