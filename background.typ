#import "utility.typ": *

= Background


== Concurrency, Synchronization & Mutual Exclusion <head:concurrency>


== Locks <head:locks>

=== Common Lock Primitive Implementations

==== Naive Spinlock <head:naive-spinlock>

==== Pthread Spinlock (test and test lock) <head:pthread-spinlock>

==== Exponential Backoff Spinlock <head:exponential-backoff-spinlock>

==== Pthread Mutex <head:mutex>

==== Ticket Lock <head:ticket-lock>

==== MCS & K42 variant <head:mcs-lock>

== Lock Usage <head:usage-fairness>

=== Scheduler Subversion <head:scheduler-subversion>

==== Imbalanced Scheduler Goals

==== Non-Preemptive Scheduling

== Usage-Fair Lock <head:usage-fairness>

=== Scheduler-Cooperative Locks

==== u-SCL

==== k-SCL

==== RW-SCL

=== CFL

@cfl_ref

== Delegation Styled Locks <head:delegation-styled-locks>

=== Combine Style Locks <head:combine-style-locks>

==== Flat Combining <head:flat-combining>

@flatcombining_ref

==== CCSynch/DSM-Synch <head:ccsynch-dsm-synch>

@ccsynch_ref

=== Client-Server Styled Locks <head:client-server-styled-locks>

#todo

==== RCL <head:rcl>

@rcl_ref

#not-sure 
==== ffwd <head:ffwd>

@ffwd_ref

#not-sure

== Lock-Free Data Structures <head:lock-free-data-structures>

=== Linked List <head:lock-free-linked-list>

@aomp_ref

=== Skip-List <head:lock-free-skip-list>

@aomp_ref @skiplist_ref

=== Priority Queue <head:lock-free-priority-queue>

@aomp_ref

=== MPSC Channel <head:mpsc-channel>

@ringbuffer_ref

#pagebreak(weak: true)

#include "bibliography.typ"
