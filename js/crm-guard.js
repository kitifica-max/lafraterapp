(async () => {
  const { data: { session } } = await window.supabaseClient.auth.getSession();
  if (!session) { window.location.replace('/crm-login.html'); return; }

  const role = session.user?.user_metadata?.role || session.user?.app_metadata?.role;
  const allowedRoles = ['admin', 'lider'];

  if (!allowedRoles.includes(role)) {
    await window.supabaseClient.auth.signOut();
    window.location.replace('/crm-login.html');
    return;
  }

  // Exponer rol globalmente
  window.crmRole = role;

  const nombre = session.user?.user_metadata?.nombre || session.user?.email?.split('@')[0] || 'Admin';
  document.querySelectorAll('.crm-admin-name').forEach(el => el.textContent = nombre);
  document.querySelectorAll('.crm-topbar-user').forEach(el => el.textContent = nombre);

  // Páginas restringidas solo para Admin
  const adminOnlyPages = [
    'crm-usuarios.html',
    'crm-plan.html',
    'crm-servicios.html',
    'crm-ofrenda.html',
    'crm-facultad.html'
  ];

  const currentPage = window.location.pathname.split('/').pop();

  if (role === 'lider') {
    // 1. Redirigir si intenta entrar a una página prohibida
    if (adminOnlyPages.includes(currentPage)) {
      window.location.replace('/crm-dashboard.html');
      return;
    }
    // 2. Ocultar elementos marcados como solo-admin (incluyendo items del sidebar)
    document.querySelectorAll('[data-only-admin]').forEach(el => el.style.display = 'none');
  }
})();

async function crmLogout() {
  await window.supabaseClient.auth.signOut();
  window.location.replace('/crm-login.html');
}

function isAdmin() { return window.crmRole === 'admin'; }
