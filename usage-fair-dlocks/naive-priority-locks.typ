#import "../utils.typ": *


== Naive Priority Locks

There are two main problems with the banning strategy:

1. The banning strategy is heuristic.
2. The banning strategy is not work-conserving.
3. When some threads only occasionally acquire the lock, they will increase the banning time of other threads. This will degrade the performance of the lock.

Built upon the above problems, we want propose a new design that is both fair and work-conserving. This section proposes a new design that drives the same idea as Linux CFS.

The goal of this chapter:

+ Usage-Fair: The lock should allocate similar amount of time to each thread.
+ Low Latency: If a thread has low usage, it should be prioritized.
+ Work-Conserving: The lock should not be idle when there are threads waiting.
+ "Relatively" performance: The lock should be as fast as possible.

The design of this chapter encompases the following components:

+ A policy to elect a combiner.
+ A concurrent scheduler allows scheduling the next critical section.

=== FC-Skiplist

This section we introduces a prototype that adopts the above design.

We starts with a combiner election policy that is similar to how #fc works @flatcombining_ref. The combiner election policy of #fc is pretty simple: using an `AtomicBool` to achieve consensus about the current combiner.

Whenever threads are trying to acquire the lock, they will check the `AtomicBool` is set. If it is set, then it knows that there is a current combiner which may be able to execute its critical section. If not, it will perform a `CAS` operation to set the `AtomicBool` to achieve consensus about whether there is a current combiner.


@skiplist_ref


#include "../reference.typ"