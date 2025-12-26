-- INVESTIGAR CAUSA RAÍZ DEL ERROR DE BASE DE DATOS

-- 1. Ver Políticas RLS en 'profiles'
-- A veces el trigger falla porque intenta insertar pero la política lo bloquea
SELECT * FROM pg_policies WHERE tablename = 'profiles';

-- 2. Ver Constraints de la tabla 'profiles'
-- Verificar si 'attendee' es un valor válido para la columna 'role'
SELECT * FROM information_schema.check_constraints WHERE constraint_name LIKE '%role%'; 

-- 3. Ver Permisos del usuario actual (postgres/anon/authenticated)
SELECT current_user, session_user;
