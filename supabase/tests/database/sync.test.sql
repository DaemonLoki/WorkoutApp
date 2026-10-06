-- sync_push / sync_pull and Row Level Security (README §10). Run with `supabase test db`.
begin;
create extension if not exists pgtap with schema extensions;
select plan(15);

insert into auth.users (id, email) values
    ('00000000-0000-0000-0000-00000000000a', 'owner@example.com'),
    ('00000000-0000-0000-0000-00000000000b', 'someone-else@example.com');

create function pg_temp.sign_in(uid uuid) returns void language sql as $$
    select set_config('role', 'authenticated', true),
        set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
$$;

create function pg_temp.workout(name text, updated_at text, deleted_at text default null) returns jsonb
language sql as $$
    select jsonb_build_object('workouts', jsonb_build_array(jsonb_build_object(
        'id', '10000000-0000-0000-0000-000000000001',
        'created_at', '2026-09-01T10:00:00.000Z', 'updated_at', updated_at, 'deleted_at', deleted_at,
        'name', name, 'rotation_index', 0)));
$$;

-- Signed in as the owner.
select pg_temp.sign_in('00000000-0000-0000-0000-00000000000a');

select public.sync_push(pg_temp.workout('Leg Day', '2026-09-01T10:00:00.000Z'));
select is(
    public.sync_pull(null) -> 'workouts' -> 0 ->> 'name', 'Leg Day',
    'a pushed Workout comes back from a pull');

select public.sync_push(pg_temp.workout('Legs (older edit)', '2026-09-01T09:00:00.000Z'));
select is(
    public.sync_pull(null) -> 'workouts' -> 0 ->> 'name', 'Leg Day',
    'an older edit is ignored');

select public.sync_push(pg_temp.workout('Legs', '2026-09-02T10:00:00.000Z'));
select is(
    public.sync_pull(null) -> 'workouts' -> 0 ->> 'name', 'Legs',
    'a newer edit wins');

select is(
    (public.sync_pull(null) -> 'workouts' -> 0) ?| array['user_id', 'server_updated_at'], false,
    'pulled rows carry only what the app stores');

-- The cursor: only rows changed after it come back.
select public.sync_push($$ {"workouts": [{
    "id": "10000000-0000-0000-0000-000000000002",
    "created_at": "2026-09-03T10:00:00.000Z", "updated_at": "2026-09-03T10:00:00.000Z",
    "name": "Pull Day", "rotation_index": 1
}]} $$);
select is(
    (select count(*) from jsonb_array_elements(
        public.sync_pull((select max(server_updated_at) from public.workouts
            where id = '10000000-0000-0000-0000-000000000001')) -> 'workouts')),
    1::bigint,
    'a pull since the cursor returns only rows changed after it');
select is(
    (public.sync_pull(null) ->> 'cursor')::timestamptz, (select max(server_updated_at) from public.workouts),
    'the cursor is the newest server change');
select is(
    public.sync_pull(now() + interval '1 day') -> 'workouts', '[]'::jsonb,
    'nothing new since the cursor returns empty lists');

select public.sync_push(pg_temp.workout('Legs', '2026-09-04T10:00:00.000Z', '2026-09-04T10:00:00.000Z'));
select isnt(
    (select w ->> 'deleted_at' from jsonb_array_elements(public.sync_pull(null) -> 'workouts') w
        where w ->> 'id' = '10000000-0000-0000-0000-000000000001'),
    null,
    'a deletion arrives as a tombstone');

-- One row of every table, keyed exactly as the app encodes it.
select lives_ok($$ select public.sync_push($json$ {
    "exercises": [{"id": "20000000-0000-0000-0000-000000000001", "created_at": "1970-01-01T00:00:00.000Z",
        "updated_at": "1970-01-01T00:00:00.000Z", "deleted_at": null, "name": "Back Squat", "equipment": "barbell",
        "muscle_groups": ["quads", "glutes", "upperBack"], "catalog_key": "back-squat",
        "strava_exercise_type": null, "archived_at": null}],
    "planned_exercises": [{"id": "30000000-0000-0000-0000-000000000001", "created_at": "2026-09-01T10:00:00.000Z",
        "updated_at": "2026-09-01T10:00:00.000Z", "workout_id": "10000000-0000-0000-0000-000000000001",
        "exercise_id": "20000000-0000-0000-0000-000000000001", "position": 0, "superset_id": null,
        "link_id": null, "target_sets": 3, "target_reps": 8, "weight": 82.5, "weight_step": 2.5,
        "rest_seconds": 120}],
    "sessions": [{"id": "40000000-0000-0000-0000-000000000001", "created_at": "2026-09-05T18:00:00.000Z",
        "updated_at": "2026-09-05T19:00:00.000Z", "workout_id": "10000000-0000-0000-0000-000000000001",
        "workout_name": "Legs", "started_at": "2026-09-05T18:00:00.000Z", "ended_at": "2026-09-05T19:00:00.000Z",
        "recorded_on": "watch", "strava_activity_id": null}],
    "session_exercises": [{"id": "50000000-0000-0000-0000-000000000001",
        "created_at": "2026-09-05T18:00:00.000Z", "updated_at": "2026-09-05T19:00:00.000Z",
        "session_id": "40000000-0000-0000-0000-000000000001", "exercise_id": "20000000-0000-0000-0000-000000000001",
        "planned_exercise_id": "30000000-0000-0000-0000-000000000001", "exercise_name": "Back Squat",
        "position": 0, "superset_id": null, "target_sets": 3, "target_reps": 8, "target_weight": 82.5,
        "status": "done", "skipped_sets": 0}],
    "sets": [{"id": "60000000-0000-0000-0000-000000000001", "created_at": "2026-09-05T18:05:00.000Z",
        "updated_at": "2026-09-05T18:05:00.000Z", "session_exercise_id": "50000000-0000-0000-0000-000000000001",
        "number": 1, "reps": 8, "weight": 82.5, "is_extra": false, "completed_at": "2026-09-05T18:05:00.000Z"}],
    "progression_suggestions": [{"id": "70000000-0000-0000-0000-000000000001",
        "created_at": "2026-09-05T19:00:00.000Z", "updated_at": "2026-09-05T19:00:00.000Z",
        "planned_exercise_id": "30000000-0000-0000-0000-000000000001", "kind": "stepUp", "reason": "targetHit",
        "from_weight": 82.5, "to_weight": 85, "source_session_id": "40000000-0000-0000-0000-000000000001",
        "status": "pending", "resolved_at": null}]
} $json$) $$, 'a row of every table is accepted');

select throws_ok($$ select public.sync_push($json$ {"exercises": [{"id": "20000000-0000-0000-0000-000000000002",
    "created_at": "2026-09-01T10:00:00.000Z", "updated_at": "2026-09-01T10:00:00.000Z", "name": "Sled Push",
    "equipment": "sled", "muscle_groups": []}]} $json$) $$,
    '23514', null, 'an unknown equipment is rejected');

-- Someone else.
select pg_temp.sign_in('00000000-0000-0000-0000-00000000000b');

select is((select count(*) from public.workouts), 0::bigint, 'nobody sees another user''s rows');
select is(public.sync_pull(null) -> 'workouts', '[]'::jsonb, 'nobody pulls another user''s rows');

select lives_ok($$ select public.sync_push($json$ {"exercises": [{"id": "20000000-0000-0000-0000-000000000001",
    "created_at": "1970-01-01T00:00:00.000Z", "updated_at": "1970-01-01T00:00:00.000Z", "name": "Back Squat",
    "equipment": "barbell", "muscle_groups": ["quads"], "catalog_key": "back-squat"}]} $json$) $$,
    'two users can store the same catalog Exercise id');

-- Signed out.
select set_config('role', 'anon', true);
select throws_ok($$ select public.sync_push('{}') $$, '42501', null, 'signed out, nothing can be pushed');

-- Account deletion (`delete-account` deletes the auth user).
reset role;
delete from auth.users where id = '00000000-0000-0000-0000-00000000000a';
select is(
    (select count(*) from public.workouts where user_id = '00000000-0000-0000-0000-00000000000a')
        + (select count(*) from public.sets where user_id = '00000000-0000-0000-0000-00000000000a'),
    0::bigint,
    'deleting the account deletes every row of it');

select * from finish();
rollback;
