-- Synced tables (README §10). Every table carries the sync identity and clocks:
--   updated_at        client clock of the last change; decides conflicts (last write wins)
--   deleted_at        tombstone; rows are never deleted by the app
--   server_updated_at set by trigger; only the pull cursor
-- Cross-table references are plain columns without foreign keys, so partial or out-of-order
-- pushes never fail; the app keeps integrity.

create function public.touch_server_updated_at() returns trigger
language plpgsql
set search_path = ''
as $$
begin
    new.server_updated_at := clock_timestamp();
    return new;
end;
$$;

create table public.exercises (
    user_id              uuid        not null default auth.uid() references auth.users on delete cascade,
    id                   uuid        not null,
    created_at           timestamptz not null,
    updated_at           timestamptz not null,
    deleted_at           timestamptz,
    server_updated_at    timestamptz not null default clock_timestamp(),
    name                 text        not null,
    equipment            text        not null
        check (equipment in ('barbell', 'dumbbell', 'machine', 'cable', 'bodyweight', 'kettlebell')),
    muscle_groups        text[]      not null default '{}'
        check (muscle_groups <@ array[
            'chest', 'lats', 'upperBack', 'lowerBack', 'traps', 'shoulders', 'biceps', 'triceps', 'forearms',
            'abs', 'obliques', 'glutes', 'quads', 'hamstrings', 'adductors', 'calves'
        ]::text[]),
    catalog_key          text,
    strava_exercise_type text,
    archived_at          timestamptz,
    primary key (user_id, id)
);

create table public.workouts (
    user_id           uuid        not null default auth.uid() references auth.users on delete cascade,
    id                uuid        not null,
    created_at        timestamptz not null,
    updated_at        timestamptz not null,
    deleted_at        timestamptz,
    server_updated_at timestamptz not null default clock_timestamp(),
    name              text        not null,
    rotation_index    int         not null,
    primary key (user_id, id)
);

create table public.planned_exercises (
    user_id           uuid          not null default auth.uid() references auth.users on delete cascade,
    id                uuid          not null,
    created_at        timestamptz   not null,
    updated_at        timestamptz   not null,
    deleted_at        timestamptz,
    server_updated_at timestamptz   not null default clock_timestamp(),
    workout_id        uuid,
    exercise_id       uuid,
    position          int           not null,
    superset_id       uuid,
    link_id           uuid,
    target_sets       int           not null,
    target_reps       int           not null,
    weight            numeric(6, 2) not null,
    weight_step       numeric(5, 2) not null,
    rest_seconds      int           not null,
    primary key (user_id, id)
);

create table public.sessions (
    user_id            uuid        not null default auth.uid() references auth.users on delete cascade,
    id                 uuid        not null,
    created_at         timestamptz not null,
    updated_at         timestamptz not null,
    deleted_at         timestamptz,
    server_updated_at  timestamptz not null default clock_timestamp(),
    workout_id         uuid,
    workout_name       text        not null,
    started_at         timestamptz not null,
    ended_at           timestamptz,
    recorded_on        text        not null check (recorded_on in ('phone', 'watch')),
    strava_activity_id bigint,
    primary key (user_id, id)
);

create table public.session_exercises (
    user_id             uuid          not null default auth.uid() references auth.users on delete cascade,
    id                  uuid          not null,
    created_at          timestamptz   not null,
    updated_at          timestamptz   not null,
    deleted_at          timestamptz,
    server_updated_at   timestamptz   not null default clock_timestamp(),
    session_id          uuid,
    exercise_id         uuid          not null,
    planned_exercise_id uuid,
    exercise_name       text          not null,
    position            int           not null,
    superset_id         uuid,
    target_sets         int           not null,
    target_reps         int           not null,
    target_weight       numeric(6, 2) not null,
    status              text          not null check (status in ('pending', 'done', 'skipped')),
    skipped_sets        int           not null default 0,
    primary key (user_id, id)
);

create table public.sets (
    user_id             uuid          not null default auth.uid() references auth.users on delete cascade,
    id                  uuid          not null,
    created_at          timestamptz   not null,
    updated_at          timestamptz   not null,
    deleted_at          timestamptz,
    server_updated_at   timestamptz   not null default clock_timestamp(),
    session_exercise_id uuid,
    number              int           not null,
    reps                int           not null,
    weight              numeric(6, 2) not null,
    is_extra            bool          not null default false,
    completed_at        timestamptz   not null,
    primary key (user_id, id)
);

create table public.progression_suggestions (
    user_id             uuid          not null default auth.uid() references auth.users on delete cascade,
    id                  uuid          not null,
    created_at          timestamptz   not null,
    updated_at          timestamptz   not null,
    deleted_at          timestamptz,
    server_updated_at   timestamptz   not null default clock_timestamp(),
    planned_exercise_id uuid          not null,
    kind                text          not null check (kind in ('stepUp', 'stepDown')),
    reason              text          not null check (reason in ('targetHit', 'stall', 'layoff')),
    from_weight         numeric(6, 2) not null,
    to_weight           numeric(6, 2) not null,
    source_session_id   uuid,
    status              text          not null check (status in ('pending', 'accepted', 'dismissed', 'superseded')),
    resolved_at         timestamptz,
    primary key (user_id, id)
);

-- Same for every synced table: pull index, server clock trigger, owner-only access.
do $$
declare
    synced text;
begin
    foreach synced in array array[
        'exercises', 'workouts', 'planned_exercises', 'sessions', 'session_exercises', 'sets',
        'progression_suggestions'
    ] loop
        execute format('create index %I on public.%I (user_id, server_updated_at)', synced || '_pull', synced);
        execute format(
            'create trigger touch_server_updated_at before update on public.%I '
            'for each row execute function public.touch_server_updated_at()', synced);
        execute format('alter table public.%I enable row level security', synced);
        execute format(
            'create policy "Owner only" on public.%I for all to authenticated '
            'using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()))', synced);
        execute format('revoke all on public.%I from anon', synced);
    end loop;
end;
$$;
