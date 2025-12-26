select pg_get_functiondef(oid) from pg_proc where proname = 'handle_new_user';
