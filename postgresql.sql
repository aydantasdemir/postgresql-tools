

select now()-query_start as time_elapsed,'pg_terminate_backend(' || pid || ')' as pid,datname,usename,state,waiting, ( select count(pid) from pg_locks where pid=t.pid ) as locks, ( select count(pid) from pg_locks where pid=t.pid and granted=false  ) as granted_locks from pg_stat_activity as t  order by datname;

