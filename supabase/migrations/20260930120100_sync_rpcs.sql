-- The two sync calls (README §10). Both run as the caller, so Row Level Security scopes them to
-- the signed-in user. Payloads are keyed by table name; rows use the tables' column names.

-- Upserts every row in one transaction; per row, the newer client `updated_at` wins.
create function public.sync_push(payload jsonb) returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
    synced  text;
    columns text;
    updates text;
begin
    foreach synced in array array[
        'exercises', 'workouts', 'planned_exercises', 'sessions', 'session_exercises', 'sets',
        'progression_suggestions'
    ] loop
        select
            string_agg(quote_ident(column_name), ', ' order by ordinal_position),
            string_agg(format('%1$I = excluded.%1$I', column_name), ', ' order by ordinal_position)
        into columns, updates
        from information_schema.columns
        where table_schema = 'public' and table_name = synced
            and column_name not in ('user_id', 'server_updated_at');

        execute format(
            'insert into public.%1$I as t (%2$s) '
            'select %2$s from jsonb_populate_recordset(null::public.%1$I, $1) '
            'on conflict (user_id, id) do update set %3$s where t.updated_at < excluded.updated_at',
            synced, columns, updates)
        using coalesce(payload -> synced, '[]'::jsonb);
    end loop;
end;
$$;

-- Every row changed on the server after `since` (all rows when null), plus the cursor for the next pull.
create function public.sync_pull(since timestamptz) returns jsonb
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
    synced  text;
    rows    jsonb;
    latest  timestamptz;
    result  jsonb := '{}'::jsonb;
    cursor  timestamptz := since;
begin
    foreach synced in array array[
        'exercises', 'workouts', 'planned_exercises', 'sessions', 'session_exercises', 'sets',
        'progression_suggestions'
    ] loop
        execute format(
            'select coalesce(jsonb_agg(to_jsonb(t) - ''user_id'' - ''server_updated_at''), ''[]''::jsonb), '
            'max(t.server_updated_at) '
            'from public.%I t where t.user_id = (select auth.uid()) and ($1 is null or t.server_updated_at > $1)',
            synced)
        into rows, latest
        using since;
        result := result || jsonb_build_object(synced, rows);
        cursor := greatest(cursor, latest);
    end loop;
    return result || jsonb_build_object('cursor', cursor);
end;
$$;

revoke execute on function public.sync_push(jsonb), public.sync_pull(timestamptz) from public, anon;
grant execute on function public.sync_push(jsonb), public.sync_pull(timestamptz) to authenticated;
