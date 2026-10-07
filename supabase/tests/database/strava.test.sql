-- Strava connections (README §12): tokens are out of the app's reach; the RPCs show only the
-- caller's own connection. Run with `supabase test db`.
begin;
create extension if not exists pgtap with schema extensions;
select plan(8);

insert into auth.users (id, email) values
    ('00000000-0000-0000-0000-00000000000a', 'owner@example.com'),
    ('00000000-0000-0000-0000-00000000000b', 'someone-else@example.com');

-- What strava-connect writes with the service role.
insert into public.strava_connections (user_id, athlete_id, access_token, refresh_token, expires_at, scope, created_at)
values ('00000000-0000-0000-0000-00000000000a', 1234567, 'access-secret', 'refresh-secret',
        '2026-10-06T18:00:00Z', 'activity:write', '2026-10-06T12:00:00Z');

create function pg_temp.sign_in(uid uuid) returns void language sql as $$
    select set_config('role', 'authenticated', true),
        set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
$$;

select pg_temp.sign_in('00000000-0000-0000-0000-00000000000a');

select throws_ok(
    'select access_token from public.strava_connections', '42501', null,
    'the app cannot read Strava tokens, not even its own');
select throws_ok(
    $$ update public.strava_connections set athlete_id = 1 $$, '42501', null,
    'the app cannot change a connection directly');
select is(
    public.strava_connection(), '{"connected_at": "2026-10-06T12:00:00+00:00", "auto_upload": true}'::jsonb,
    'the owner sees when they connected and whether auto-upload is on, nothing else');

select public.set_strava_auto_upload(false);
select is(
    public.strava_connection() ->> 'auto_upload', 'false',
    'the owner can turn auto-upload off');

select pg_temp.sign_in('00000000-0000-0000-0000-00000000000b');

select is(public.strava_connection(), null, 'someone else sees no connection');
select public.set_strava_auto_upload(true);

reset role;
select is(
    (select auto_upload from public.strava_connections where user_id = '00000000-0000-0000-0000-00000000000a'),
    false, 'someone else cannot change the owner''s auto-upload');

-- The cloud keeps our own upload mark; Strava's activity ID stays on the iPhone (README §12).
select hasnt_column('public', 'sessions', 'strava_activity_id', 'sessions keep no Strava activity ID');
select has_column('public', 'sessions', 'strava_uploaded_at', 'sessions keep when they reached Strava');

select * from finish();
rollback;
