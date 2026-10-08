-- Rep Step Ups (README §4): a Step Up offers one more rep as well as one Weight Step, and a Step Down
-- at 0 kg lowers the reps. Null for suggestions from before, whose reps don't change.
alter table public.progression_suggestions
    add column from_reps int check (from_reps between 1 and 50),
    add column to_reps   int check (to_reps between 1 and 50);
