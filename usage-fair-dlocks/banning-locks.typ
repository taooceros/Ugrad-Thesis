#import "../utility.typ": *
#import "@preview/codly:1.1.1": *
#import "@preview/codly-languages:0.1.3": *

#show: codly-init.with()

#codly(languages: (
  rust: (name: "Rust", icon: "🦀", color: rgb("#CE412B")),
))

== Banning Locks

We start by migrating the banning strategy of #scls to the delegation styled locks. As mentioned in (@), #scls adopts the following banning strategy:

$
  t_"banned until" = t_"last unlock" + t_"lock duration" * (w_"thread" / w_"total")
$

where $t_"last unlock"$ is the timestamp of the last unlock of the lock, $t_"lock duration"$ is the duration of the lock, $w_"thread"$ is the weight of the thread, and $w_"total"$ is the total weight of all threads.

By adopting a similar banning strategy, we dervie #fc-banning and #cc-synch-banning in this section.

=== Flat Combining (with Banning) <head:flat-combining-banning>

Implementing the banning strategy for #fc is straightforward, because in #fc, each thread owns its own node @flatcombining_ref. Therefore, we can simply record the banning time of the thread in the node and skip the critical section if the thread is banned.

The first step is to calculate the lock usage. Since only the combiner knows when the lock starts to acquire, we have two solutions to calculate the lock usage.

+ Let the combiner to record the timestamp before start executing a critical section, and then record again after finishing the critical section, then calculate the banning time of the thread.
+ Let the combiner to record the timestamp before start executing a critical section, and then pass the timestamp to the node before marking the job as finished. Then the waiter can calculate the lock usage by subtracting the timestamp from the current time, and mark itself as banned.

We implement the first solution in this thesis for simplicity. It may incur a tiny performance overhead since the combiner is doing more work. However, combiner will need to record the timestamp before start executing a critical section regardless and thus it can reuse the last unlock time as the start time of the next job with some small errors, which reduces the additional timestamp recording overhead. While although accessing $w_"total"$ may incur a memory stall, the modification of $w_"total"$ is rare (only happens when a new thread joins the lock because the combiner won't clean the old thread's weight until after finish the current pass) and thus the performance impact is acceptable.

@code:fc-banning-node refers to the node structure of #fc with banning. The first 4 fields are the same as the node of #fc, and the last field is the next available timestamp to execute the critical section of the thread.



#figure(caption: [Node structure of #fc-banning])[
  ```rust
    pub struct Node<T> {
        pub age: UnsafeCell<u32>,
        pub active: AtomicBool,
        pub data: SyncUnsafeCell<T>,
        pub complete: AtomicBool,
        pub next: AtomicPtr<Node<T>>,
        pub banned_until: SyncUnsafeCell<u64>,
    }
  ```
]<code:fc-banning-node>


@code:fc-banning-lock refers to the lock structure of #fc with banning. The first 4 fields are the same as the lock of #fc, and the last field is the next available timestamp to execute the critical section of the thread.

#figure(caption: [Lock structure of #fc-banning])[
  ```rust
  pub struct FCBan<T, I, F, L>
  where
      T: Send + Sync,
      I: Send,
      F: Fn(&mut T, I) -> I,
      L: RawMutex,
  {
      pass: AtomicU32,
      combiner_lock: CachePadded<L>,
      delegate: F,
      num_waiting_threads: AtomicI64,
      data: SyncUnsafeCell<T>,
      head: AtomicPtr<Node<I>>,
      local_node: ThreadLocal<SyncUnsafeCell<Node<I>>>,
  }
  ```
]<code:fc-banning-lock>

@code:fc-banning-combine is a pseudo rust code #footnote[
  omitting some rust details of unsafe and atomic operations: access the `UnsafeCell` and atomic load/store operations.
] of the combining function of #fc with banning. We can see that the combiner is executing the critical section of the thread only if the thread is not banned (@code:fc-banning-combine:11). Start at @code:fc-banning-combine:11, the combiner uses the current timestamp to calculate the lock usage and then update the banned time of the thread.


#figure(caption: [Combining function of #fc-banning])[
  #codly(highlights: (
    (line: 7, start: 20, end: none, fill: red),
  ))
  ```rust fn combine(&self) {
      let mut current_ptr = NonNull::new(self.head);

      while let Some(current) = current_ptr {
          if current.active && !current.complete {
              unsafe {
                  current.age = pass;
                  if work_begin >= current.banned_until {
                      ... // perform the delegation work
                      current.complete = true;
                      let work_end = __rdtscp(&mut aux);
                      // Banning
                      let cs = (work_end - work_begin);
                      current.banned_until += cs * (self.num_waiting_threads);
                      work_begin = work_end;
                  }
              }
          }
          current_ptr = NonNull::new(current.next);
      }
  }
  ```
]<code:fc-banning-combine>

=== CCSynch with Banning <head:ccsynch-banning>

The implementation of #cc-synch with banning is slightly more complex than #fc-banning, because in #cc-synch, the nodes are cycled and utilized by different threads each time to ensure the FIFO order of the execution. Therefore, threads must maintain additional thread-local data to record the banned time.

Compared to #fc-banning, #cc-synch-banning assigns the threads that trying to acquire the lock to spin (or wait) until its own banned time is passed for simplicity. This is slightly more performant compared to #fc-banning: the combiner in #fc-banning needs to perform additional checking toward whether a thread is banned.

@code:ccsynch-banning-node demonstrates the thread local structure and the node structure of #cc-synch-banning. At @code:ccsynch-banning-node:3 we see the additional thread-local data used to detect whether the thread is banned.

#figure(caption: [Node structure of #cc-synch-banning], supplement: [Code Block])[
  ```rust
  pub struct ThreadData<T> {
      pub(crate) node: AtomicPtr<Node<T>>,
      pub(crate) banned_until: SyncUnsafeCell<u64>,
  }

  pub struct Node<T> {
    pub age: SyncUnsafeCell<u32>,
    pub active: AtomicBool,
    pub data: SyncUnsafeCell<T>,
    pub completed: AtomicBool,
    pub wait: AtomicBool,
    pub banned_until: SyncUnsafeCell<u64>,
    pub next: AtomicPtr<Node<T>>,
  }
  ```
]<code:ccsynch-banning-node>

@code:ccsynch-banning-lock demonstrates the lock structure of #cc-synch-banning. This is identical to the lock structure of #cc-synch, except that it adds aan additional field `num_waiting_threads` to record the number of threads waiting for the lock.


#figure(caption: [Lock structure of #cc-synch-banning])[
  ```rust
  #[derive(Debug, Default)]
  pub struct CCBan<T, I, F>
  where
      F: DLock2Delegate<T, I>,
  {
      delegate: F,
      data: SyncUnsafeCell<T>,
      tail: AtomicPtr<Node<I>>,
      num_waiting_threads: AtomicU64,
      local_node: ThreadLocal<ThreadData<I>>,
  }
  ```
]<code:ccsynch-banning-lock>


@ccsynch_ref


#include "../reference.typ"