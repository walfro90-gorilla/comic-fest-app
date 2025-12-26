-- INVESTIGAR TRIGGER DE AUTH
-- Es muy probable que tengas un trigger en auth.users que llama a una función para crear el perfil.
-- Vamos a revisar las funciones automáticas comunes.

-- 1. Ver el contenido de 'handle_new_user' (Nombre estándar en Supabase)
SELECT pg_get_functiondef(oid) 
FROM pg_proc 
WHERE proname = 'handle_new_user';
