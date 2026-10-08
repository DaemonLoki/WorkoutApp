-- The Strava capacity gate (README §12, docs/research/strava-athlete-capacity.md). Strava lets an API
-- app connect a limited number of athletes and refuses everyone else on its consent page, which the app
-- can't detect. The owner keeps `athlete_capacity` at what Strava granted (1 for a new app, 10 after the
-- self-upgrade, more after Strava's review):
--     update public.strava_settings set athlete_capacity = 10;
create table public.strava_settings (
    -- One row only.
    id               bool primary key default true check (id),
    athlete_capacity int  not null check (athlete_capacity >= 0)
);

insert into public.strava_settings (athlete_capacity) values (1);

alter table public.strava_settings enable row level security;
revoke all on public.strava_settings from anon, authenticated;

-- Whether "Connect with Strava" can work for the caller: already connected (reconnecting takes no new
-- slot), or a slot is free. Says nothing about how many athletes are connected.
create function public.strava_connect_open() returns bool
language sql
stable
security definer
set search_path = ''
as $$
    select exists (select 1 from public.strava_connections where user_id = (select auth.uid()))
        or (select count(*) from public.strava_connections)
            < (select athlete_capacity from public.strava_settings);
$$;

revoke execute on function public.strava_connect_open() from public, anon;
grant execute on function public.strava_connect_open() to authenticated;
