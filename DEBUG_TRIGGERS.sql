-- SCRIPT DE DEPURACIÓN (Corre esto en SQL Editor)

-- 1. Ver qué triggers existen en la tabla 'profiles'
-- Busca si hay alguno duplicado o con nombre sospechoso (ej. 'on_profile_created' viejo)
SELECT trigger_name, action_statement 
FROM information_schema.triggers 
WHERE event_object_table = 'profiles';

-- 2. Ver el valor por defecto de la columna 'points'
SELECT column_name, column_default 
FROM information_schema.columns 
WHERE table_name = 'profiles' AND column_name = 'points';
