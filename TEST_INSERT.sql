-- PRUEBA DE INSERCIÓN MANUAL
-- Intentamos insertar un perfil falso directamente para ver el error real.

DO $$
BEGIN
    -- Intentar insertar un usuario dummy con ID aleatorio
    INSERT INTO public.profiles (id, email, username, role, points)
    VALUES (
        gen_random_uuid(), -- ID falso
        'test_debug@comicfest.app', 
        'Test User', 
        'attendee', 
        0
    );
EXCEPTION WHEN OTHERS THEN
    -- Si falla, mostrar el error exacto
    RAISE NOTICE '❌ ERROR DE SQL: %', SQLERRM;
END $$;
