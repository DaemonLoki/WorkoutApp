-- Rest Timer per Workout (README §6): off, the Workout's Sessions time no Rest.
alter table public.workouts add column uses_rest_timer bool not null default true;
