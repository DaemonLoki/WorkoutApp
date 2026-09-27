# The iPhone is the only cloud client; the Watch syncs through it

The Watch app is fully standalone during a Session, but it never talks to Supabase. It exchanges records with the iPhone over WatchConnectivity (`updateApplicationContext` for the plan snapshot, `transferUserInfo` for finished Sessions), using the same last-write-wins merge as cloud sync. This keeps auth, tokens and the `supabase-swift` dependency out of the Watch target, and a Watch-recorded Session reaches the cloud as soon as the phone is back in range.

During a live Session the device running the `HKWorkoutSession` (the Watch when available) is the single writer of that Session; the other device only mirrors state and sends commands, so Sessions are never duplicated.
