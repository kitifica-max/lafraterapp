# Landing Page Restructure — Design Spec
Date: 2026-04-23

## Objetivo
Reestructurar index.html para presentar La Frater como institución y luego invitar a la audiencia a unirse — físicamente (servicios) y digitalmente (app PWA).

## Audiencia
Mix de nuevos visitantes y personas que ya conocen la iglesia. Acción deseada: asistir un domingo O instalar la app (igual peso).

## Nueva estructura de secciones (orden)

| # | Sección | Fondo | Descripción |
|---|---------|-------|-------------|
| 1 | **Hero** | Navy gradient | Headline + carrusel comunidad (6 cards) + 2 CTAs |
| 2 | **Identidad** | Blanco | Visión, Misión, 3 Pilares + link a Sobre Nosotros |
| 3 | **Servicios** | Navy | Horario dominical, ubicación, oficina, transporte |
| 4 | **App** | Azul claro | Banner compacto PWA — "Lleva la Frater contigo" |
| 5 | **Eventos** | Blanco | 3 próximos eventos desde Supabase |
| 6 | **Contacto** | Gris claro | Mapa + info cards (existente, sin cambios) |
| 7 | **CTA Final** | Navy gradient | Dos CTAs: "Visítanos" + "Instalar App" |
| 8 | **Footer** | Navy | Sin cambios |

## Secciones eliminadas
- Features grid (6 bloques de funciones app) — contenido de app, no del index
- Series/Blog — vive en la app
- features-vm-banner navy separado — reemplazado por Identidad integrada

## Hero — Carrusel de Comunidad

**Desktop:** Hero en dos columnas — texto izquierda, carrusel derecha.
**Móvil:** Columna única — tag → h1 → subtítulo → carrusel (full-width, 180px alto) → CTAs full-width.

**Especificación del carrusel:**
- Máximo 6 cards definidas en array JS en el HTML
- Cada card: `{ type: 'image'|'video', src: 'img/comunidad/...', name: 'Nombre' }`
- Auto-avance cada 4 segundos, loop infinito
- Pausa al hacer touch/hover
- Swipe táctil izquierda/derecha en móvil
- Dot indicators (6 puntos, el activo más ancho)
- Videos: `<video autoplay muted loop playsinline object-fit:cover>`
- Fotos: `<img object-fit:cover>`
- Overlay gradiente en la parte inferior con el nombre del miembro
- Archivos en `img/comunidad/` (placeholders vacíos incluidos)

## Sección Identidad

- Intro breve (2 líneas) sobre la iglesia
- Dos cards: Visión / Misión (fondo azul claro)
- 3 Pilares en grid 3 columnas:
  - 01 El Amor (SVG corazón)
  - 02 El Poder (SVG rayo)
  - 03 El Orden (SVG lista)
- Link "Conocer más →" → sobre-nosotros.html

## Sección Servicios (nueva)

Fondo navy (igual al hero). Cuatro cards informativos:
- Servicio Dominical: Dom · 10:00 – 11:30 a.m.
- Ubicación: Col. Villas de San Rafael, Santa Ana
- Oficina: Mar–Sáb · 8:30 a.m.–5:00 p.m.
- Transporte: Buses disponibles (WhatsApp)
- CTA: "Ver cómo llegar →" → ancla a #contacto

## Implementación técnica

- Solo HTML + CSS + JS vanilla (sin frameworks)
- Carrusel: JS nativo con `setInterval`, `touchstart`/`touchend`
- Carousel placeholders: 6 archivos placeholder en `img/comunidad/`
- CSS en `css/welcome.css` (extender, no reemplazar)
- No tocar otras páginas del sitio
