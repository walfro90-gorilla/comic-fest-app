-- TRIGGER SOSPECHOSO DE DUPLICAR UPDATE
-- 1. Revisar triggers actuales
SELECT trigger_name, action_statement 
FROM information_schema.triggers 
WHERE event_object_table = 'profiles';

-- 2. Reescribir función update_updated_at para garantizar inocuidad
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;
