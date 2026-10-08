-- Strava (README §12, ADR-0004). The Edge Functions keep each user's Strava tokens here with the
-- service role; the app has no access to the table, only to the two RPCs below.
create table public.strava_connections (
    user_id       uuid        primary key references auth.users on delete cascade,
    -- Webhook events name the athlete, not the user.
    athlete_id    bigint      not null unique,
    access_token  text        not null,
    -- Strava may hand out a new one on every refresh; the old one stops working at once.
    refresh_token text        not null,
    expires_at    timestamptz not null,
    scope         text        not null,
    auto_upload   bool        not null default true,
    -- Sessions finished from here on are uploaded automatically.
    created_at    timestamptz not null default now(),
    updated_at    timestamptz not null default now()
);

alter table public.strava_connections enable row level security;
revoke all on public.strava_connections from anon, authenticated;

-- The caller's connection without its tokens; null when not connected.
create function public.strava_connection() returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
    select jsonb_build_object('connected_at', c.created_at, 'auto_upload', c.auto_upload)
    from public.strava_connections c
    where c.user_id = (select auth.uid());
$$;

create function public.set_strava_auto_upload(is_on bool) returns void
language sql
security definer
set search_path = ''
as $$
    update public.strava_connections
    set auto_upload = is_on, updated_at = now()
    where user_id = (select auth.uid());
$$;

revoke execute on function public.strava_connection(), public.set_strava_auto_upload(bool) from public, anon;
grant execute on function public.strava_connection(), public.set_strava_auto_upload(bool) to authenticated;

-- Strava's activity ID is Strava Data, which may be cached for 7 days at most (Strava API Policy §6.2):
-- it stays on the iPhone that uploaded. The cloud keeps our own mark instead, so a reinstall never
-- uploads a Session twice.
alter table public.sessions drop column strava_activity_id;
alter table public.sessions add column strava_uploaded_at timestamptz;
