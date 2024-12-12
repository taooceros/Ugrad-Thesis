#import "utils.typ" : *

= Introduction

In the current landscape of computational technology, the focus to
enhance Central Processing Unit (CPU) performance has transitioned from
increasing clock speeds to multiplying core counts. This evolution has
given rise to multi-core architectures, which have become ubiquitous across
computer systems. The scalability of applications on such multi-core
infrastructures is predicated on Amdahl's Law, which postulates that the
theoretical maximum improvement achievable through parallelization is
limited by the code that must remain sequential.

A principal challenge in parallel computing is thread coordination via
shared resources. Lock-based synchronization mechanisms are widely employed
to ensure mutual exclusion and are critical for threads to communicate
accurately and reliably @ostep_ref @aomp_ref. These synchronization points,
however, are often a source of contention and can become performance
bottlenecks in a concurrent execution environment @ccsynch_ref.
Theoretically, the synchronization duration should be invariant with
respect to the number of threads; yet, contention for locks often leads to
a serious degradation in performance that is disproportionate to the
increase in thread count @ccsynch_ref @flatcombining_ref @aomp_ref.


== Scheduler Subversion and Usage Fairness

// Despite their advanced design, delegation-styled locks have been criticized
// for their complexity and difficulty in integration with complex
// applications. Recent advancements, however, have demonstrated the
// feasibility of melding delegation-styled locks with conventional lock APIs
// with _transparent delegation_, thereby broadening their potential for
// deployment in extensive systems @transparent_dlock_ref.

Newly conducted studies have introduced concerns regarding scheduler
subversion when locks are implemented without a sophisticated fairness
mechanism or are limited to fairness at the point of acquisition @scheduler_coop_locks_ref. They points out that one critical lock property, _lock usage_, is missing from the previous literacy. Consider the scenario where two threads' critical sections size are different: e.g. the first thread take three times longer to finish its critical section compared to the second thread.
The presence of _imbalanced_ critical section can disrupt the CPU's scheduling policy: allocate equitable processing time to threads. Envision a scenario where interactive threads
engaging with users are in contention with batch threads performing
background tasks, all synchronized by a lock. In the absense of principle
of usage fairness, the interactive threads may suffer from inordinate
delays in lock acquisition, thereby subverting the CPU scheduler's
objective of ensuring prompt response times for interactive tasks.


// Moreover, the issue is magnified in the context of delegation-styled locks,
// where the elected combiner thread may be burdened with an unequal share of
// work. If an interactive thread is chosen as the combiner, it could lead to
// severe latency issues for the user, thus diminishing the attractiveness of
// combining locks in systems with disparate workloads.

The non-preemtive nature makes this problem hard. It is not allowed to switch lock owners when one thread hasn't finished its own critical section. Previous work offers locks that adopt usage-fairness, such as _SCLs_ @scheduler_coop_locks_ref. However, their solutions involves several limitations. 

+ Switching lock owner incurs cost. _SCLs_ raises a workaround: lock slice. Lock slice dedicates a timeslice to a owner, eliminating the need of owner switching during the duration. However, this makes _SCLs_ non-work-conserving, wasting the lock usage if threads do not re-enter the lock immediately after releasing the lock.
+ The solution to lock usage is by banning threads based on the length of their critical sections and the number of threads that are trying to acquire the lock. However, this solution is not work-conserving and the banning strategy is based on heuristic strategy.

Some latest research proposes _CFL_ @cfl_ref, which is work-conserving and reordered similar to the linux scheduler _CFS_. However, their solution still doesn't address the foundamental performance problem causes by lock owner switching. 

== Performance issue of fair locks

Foundamentally, fair lock means that the lock owner will be switching very frequenctly (presumably every single acquire if under high contention). However, this raises serious performance problem that makes lock foundamentally slower than sequencial programs. 

In most scenario, a lock is protecting some shared memory location which requires atomic access. In general, memory can be read concurrently by multiple threads without problem. What a lock is trying to prevent is concurrent write. Whenever a thread is write to a shared memory location protected by a lock, it will carry over a memory barrier that invalidate all other cpus' cache toward the memory location. In a single threaded program, this will not incur performance penalty, because its own cache is still valid. However, in a fair lock scenario, whenever new thread is acquiring the lock (assuming the new thread does not lie in the same physical cpu as the previous thread), it will see that the cache toward the memory of the shared resource is invalidated. This forces the new cpu to re-acquire the shared memory location through at least _L3_ cache or even the underlying memory, which is significantly slower than _L1_ and _L2_ cache. What's worse is this will happen for every single acquire and release of the lock, because the lock is trying to previde fairness and switch frequenctly among threads.

Due to this problem, most modern high performance locks only adopts what's called _eventually_ fairness (which is what _SCL_ with lock slice is trying to adopt) @scheduler_coop_locks_ref #todo[some other reference]. These locks don't try to switch the lock owner for every single acquire-release, but ensure that asymtotically (or in the long term) the acquisition/usage-fairness will be achieved. However, this means that threads may suffer from large tail latency because of the unfairness.

This problem raises to a question: can we have a lock that maintains fairness in its best effort in short term while preserving performance?

== Delegation-styled locks

_Delegation-styled_ locks have emerged as a innovative solution aimed at
boosting synchronization efficiency by minimizing contention and the
associated overhead of data movement. Instead of each thread compete for a
lock to execute their critical section, threads package their critical
sections into requests and entrust them to a combiner, which processes
these requests and returns the results. This execution manner allows the lock to switch owner (by executing other threads' critical sections) while do not need to invalidate cache (because it is still the same CPU that is accessing the shared memory location).


There are two predominant forms of
delegation-styled locks: _combining_ synchronization @ccsynch_ref
@tclocks_ref @flatcombining_ref and _client-server_ synchronization
@rcl_ref @ffwd_ref. Combining locks allow for dynamic selection of the
combiner role amongst the participants, whereas client-server locks
dictates a consistent server thread to manage all requests. Empirical
evidence suggests that this technique can outperform traditional locking
mechanisms, even approaching the ideal of sequential execution efficiency
regardless of number of threads. This thesis is going to focus on combining locks, while the proposed technique can be easily adopts to the client-server locks.


Most delegation styled lock adopts either eventual acquisition fairness (@flatcombining_ref@rcl_ref@ffwd_ref) or acquisition fairness (@ccsynch_ref@tclocks_ref). However, none of them adopts usage fairness, in which the goal of this thesis is to bring delegation styled locks to the stage that it can demonstrate uncomparable advantage. We start by transforming existing delegation styled lock to a variant that adopts usage fairness through adopting the banning strategy utilized in _SCLs_ --- _FC-Ban_ and _CCSynch-Ban_. Then we modify the inner structure with a concurrent re-ordering mechamism to produce a usage fair delegation styled lock --- _FC-Skiplist_. At the very last, we show how to adopt any kind of serialized scheduling policy with delegation semantics with _FC-Channel_.

== Overview

#todo[]


#pagebreak(weak: true)

#include "reference.typ"
