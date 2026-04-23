const SUPABASE_URL = 'https://dsbsizmmvvqzhmxcuhoj.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzYnNpem1tdnZxemhteGN1aG9qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY5MjE0NzQsImV4cCI6MjA5MjQ5NzQ3NH0.UtjaGLWSmKIr609OVs1Bx_RG9eCrBxA_eB4FDLscrgk';

const { createClient } = window.supabase;
window.supabaseClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
