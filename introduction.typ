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
accurately and reliably @ostep_ref @amp_ref. These synchronization points,
however, are often a source of contention and can become performance
bottlenecks in a concurrent execution environment @ccsynch_ref.
Theoretically, the synchronization duration should be invariant with
respect to the number of threads; yet, contention for locks often leads to
a serious degradation in performance that is disproportionate to the
increase in thread count @ccsynch_ref @flatcombining_ref @amp_ref.

== Delegation-styled locks

_Delegation-styled_ locks have emerged as a innovative solution aimed at
boosting synchronization efficiency by minimizing contention and the
associated overhead of data movement. Instead of each thread compete for a
lock to execute their critical section, threads package their critical
sections into requests and entrust them to a combiner, which processes
these requests and returns the results. There are two predominant forms of
delegation-styled locks: _combining_ synchronization @ccsynch_ref
@transparent_dlock_ref @flatcombining_ref and _client-server_ synchronization
@rcl_ref @ffwd_ref. Combining locks allow for dynamic selection of the
combiner role amongst the participants, whereas client-server locks
dictates a consistent server thread to manage all requests. Empirical
evidence suggests that this technique can outperform traditional locking
mechanisms, even approaching the ideal of sequential execution efficiency
regardless of number of threads. 

=== Usage fairness

// Despite their advanced design, delegation-styled locks have been criticized
// for their complexity and difficulty in integration with complex
// applications. Recent advancements, however, have demonstrated the
// feasibility of melding delegation-styled locks with conventional lock APIs
// with _transparent delegation_, thereby broadening their potential for
// deployment in extensive systems @transparent_dlock_ref.

Newly conducted studies have introduced concerns regarding scheduler
subversion when locks are implemented without a sophisticated fairness
mechanism or are limited to fairness at the point of acquisition @scl_ref.
This is particularly problematic when threads exhibit imbalanced workloads
within their critical sections, as the presence of a lock can disrupt the
CPU's scheduling policy, which intends to allocate equitable processing
time to concurrent threads. Envision a scenario where interactive threads
engaging with users are in contention with batch threads performing
background tasks, all synchronized by a lock. In the absense of principle
of usage fairness, the interactive threads may suffer from inordinate
delays in lock acquisition, thereby subverting the CPU scheduler's
objective of ensuring prompt response times for interactive tasks.
Moreover, the issue is magnified in the context of delegation-styled locks,
where the elected combiner thread may be burdened with an unequal share of
work. If an interactive thread is chosen as the combiner, it could lead to
severe latency issues for the user, thus diminishing the attractiveness of
combining locks in systems with disparate workloads.

== Delegation-styled locks with Banning

TODO

== Delegation-styled locks with a serialized scheduler

TODO

#pagebreak(weak: true)
