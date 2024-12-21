== Lock Usage <head:usage-fairness>

Lock usage patterns significantly impact system performance and fairness in concurrent applications. While traditional locks focus primarily on mutual exclusion and basic fairness properties like FIFO ordering, they fail to address the broader implications of uneven lock acquisition patterns among competing threads.

=== Scheduler Subversion <head:scheduler-subversion>

Modern operating system schedulers employ sophisticated algorithms to ensure fair CPU time distribution among threads. However, lock usage patterns can inadvertently interfere with these scheduling decisions, leading to what we term "scheduler subversion." This phenomenon manifests in two primary ways:

==== Imbalanced Scheduler Goals
Operating system schedulers typically aim to provide proportional CPU time to threads based on their priorities and scheduling policies. However, when certain threads dominate lock acquisitions, they create indirect blocking relationships that prevent other threads from making progress during their allocated time slices. This effectively nullifies the scheduler's intended CPU time distribution, as threads spend their quantum waiting for lock releases rather than executing their critical sections.

==== Non-Preemptive Scheduling
Critical sections in traditional locks are non-preemptive by design to maintain consistency. This characteristic creates intervals where the scheduler cannot enforce its scheduling decisions, as preempting a thread holding a lock could lead to deadlocks or inconsistencies. Long critical sections thus create "priority inversions" where high-priority threads are forced to wait for lower-priority threads to complete their critical sections.

== Usage-Fair Lock <head:usage-fairness>

Usage-fair locks represent a class of synchronization primitives that explicitly track and manage lock acquisition patterns. These locks maintain per-thread usage metrics and employ various strategies to ensure that lock acquisitions are distributed fairly among competing threads over time. The key distinction from traditional locks is their consideration of historical usage patterns in making lock allocation decisions.

=== Scheduler-Cooperative Locks

Prior work introduces scheduler-cooperative locks (SCLs) @scheduler_coop_locks_ref as a solution to address scheduler subversion. SCLs track each thread's lock acquisition history and enforce fairness by temporarily preventing threads that have used the lock frequently from acquiring it again. This approach ensures that threads with less historical usage get fair opportunities to access the critical section.

SCLs implement this fairness through a "cooldown" mechanism. After a thread accumulates a certain amount of lock usage, it must wait for a cooldown period before it can acquire the lock again. During this cooldown period, other threads with less historical usage can access the critical section, preventing any single thread from monopolizing the resource.

The key innovation of SCLs is their ability to maintain fairness without requiring explicit coordination with the operating system scheduler. Instead, they achieve scheduler cooperation implicitly by managing lock acquisition patterns in a way that naturally aligns with the scheduler's goals of fair CPU time distribution.

// == Banning <ban_intro>

// ==== u-SCL

// ==== k-SCL

// ==== RW-SCL

=== CFL

Latest research proposes Completely Fair Locking (CFL) @cfl_ref, another approach to usage fairness. Unlike SCLs which use cooldown periods, CFL draws inspiration from both Linux's Completely Fair Scheduler (CFS) and the Shuffle Lock's @shuffle_lock_ref randomized fairness principles. While Shuffle Lock achieves probabilistic fairness through randomization of lock handoffs, CFL provides deterministic fairness guarantees through precise usage tracking, but using a similar shuffling mechanism as Shuffle Lock.


#include "../reference.typ"