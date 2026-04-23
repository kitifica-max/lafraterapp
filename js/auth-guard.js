(async () => {
  const { data: { session } } = await window.supabaseClient.auth.getSession();
  if (!session) {
    window.location.replace('/login.html');
  }
})();
