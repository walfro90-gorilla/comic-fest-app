-- INSPECCIONAR TRIGGERS EN POINTS_LOG
-- Buscamos triggers que se disparen AFTER INSERT en points_log
-- y que actualicen la tabla profiles.

SELECT 
    trigger_name, 
    event_manipulation, 
    action_statement 
FROM information_schema.triggers 
WHERE event_object_table = 'points_log';
