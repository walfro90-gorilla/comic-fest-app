-- BUSCANDO EL "+1000" FANTASMA
-- 1. Buscar funciones que contengan el valor '1000'
SELECT proname, prosrc
FROM pg_proc 
WHERE prosrc ILIKE '%1000%';

-- 2. Buscar triggers en profiles
SELECT trigger_name, action_statement 
FROM information_schema.triggers 
WHERE event_object_table = 'profiles';

-- 3. Ver logs
SELECT * FROM public.points_log ORDER BY created_at DESC LIMIT 5;
