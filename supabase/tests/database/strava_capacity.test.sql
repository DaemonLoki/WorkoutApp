-- The Strava capacity gate (README §12): the app asks whether "Connect with Strava" can work before
-- opening Strava's consent page, which refuses new athletes past the API app's capacity.
-- Run with `supabase test db`.
begin;
create extension if not exists pgtap with schema extensions;
select plan(7);

insert into auth.users (id, email) values
    ('00000000-0000-0000-0000-00000000000a', 'owner@example.com'),
    ('00000000-0000-0000-0000-00000000000b', 'tester@example.com');

insert into public.strava_connections (user_id, athlete_id, access_token, refresh_token, expires_at, scope)
values ('00000000-0000-0000-0000-00000000000a', 1234567, 'access', 'refresh', '2026-10-08T18:00:00Z', 'activity:write');

create function pg_temp.sign_in(uid uuid) returns void language sql as $$
    select set_config('role', 'authenticated', true),
        set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
$$;

select is(
    (select athlete_capacity from public.strava_settings), 1,
    'a new Strava API app connects only its owner');

select pg_temp.sign_in('00000000-0000-0000-0000-00000000000b');

select throws_ok(
    'select athlete_capacity from public.strava_settings', '42501', null,
    'the app cannot read the capacity');
select throws_ok(
    'update public.strava_settings set athlete_capacity = 10000', '42501', null,
    'the app cannot change the capacity');
select is(public.strava_connect_open(), false, 'nobody new can connect once every slot is used');

select pg_temp.sign_in('00000000-0000-0000-0000-00000000000a');
select is(public.strava_connect_open(), true, 'a connected athlete can always reconnect');

reset role;
update public.strava_settings set athlete_capacity = 10;

select pg_temp.sign_in('00000000-0000-0000-0000-00000000000b');
select is(public.strava_connect_open(), true, 'someone new can connect while a slot is free');

reset role;
set local role anon;
select throws_ok('select public.strava_connect_open()', '42501', null, 'signed-out callers cannot ask');

select * from finish();
rollback;
