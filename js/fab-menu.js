function toggleFabMenu() {
  const isOpen = document.getElementById('fabSheet').classList.contains('active');
  isOpen ? closeFabMenu() : openFabMenu();
}

function openFabMenu() {
  document.getElementById('fabOverlay').classList.add('active');
  document.getElementById('fabSheet').classList.add('active');
  document.querySelector('.nav-fab').classList.add('open');
}

function closeFabMenu() {
  document.getElementById('fabOverlay').classList.remove('active');
  document.getElementById('fabSheet').classList.remove('active');
  document.querySelector('.nav-fab').classList.remove('open');
}

function shareVerse() {
  closeFabMenu();
  const text = '📖 Lectura del día — Juan 1:1-14 y Salmos 23\n\nCompartido desde Frater App\nhttps://lafratersvapp.netlify.app';
  if (navigator.share) {
    navigator.share({ title: 'Versículo del día — Frater', text });
  } else {
    navigator.clipboard.writeText(text).then(() => alert('Versículo copiado al portapapeles.'));
  }
}
