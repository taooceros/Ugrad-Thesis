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

=== #fc-sl

This section we introduces a prototype that adopts the above design. The idea is to use a concurrent priority queue to schedule the next critical section. Each thread push their job into the priority queue with value being their lock usage, in which the combiner will pop the smallest value from the priority queue to schedule the next critical section. We prototype this design with a concurrent skiplist, which is a quiscently consistent concurrent priority queue @skiplist_ref.

We starts with a combiner election policy that is similar to how #fc works @flatcombining_ref. The combiner election policy of #fc is pretty simple: using an normal lock to achieve consensus about the current combiner.

Whenever threads are trying to acquire the lock, you will check the global lock is acquired. If it is acquired, then it knows that there is a current combiner which may be able to execute its critical section. If not, it will perform a `CAS` operation to set the `AtomicBool` to achieve consensus about whether there is a current combiner. This policy is identical to the combiner election policy of #fc @flatcombining_ref.

@code:fc-sl-lock demonstrate the lock function of #fc-sl. The structure of the lock is very similar to the lock function of #fc. The steps are as follows:

+ Write the critical section that needs to be applied sequentially to the shared object in the `data` field of your thread local publication record. The `complete` is set to `false` to indicate that there is a new critical section to be applied.
+ Push your thread local publication record into the skiplist.
+ Check if the global lock is acquired. If so (there is a current active combiner), spin/wait on the `complete` field of your thread-local publication record.
+ If the lock is not acquired, try to acquire it (via `CAS` or any other atomic operations), and if successful, become a combiner. If failed, then someone else already become the combiner, you will return to Step 3.
+ Otherwise, you hold the lock and become the current combiner. Execute `combine` and then unlock the lock.


#figure(caption: "lock function of FC-Skiplist")[
    ```rust
    fn lock(&self, data: I) -> I {
        let node = self.local_node.get_or(|| SyncUnsafeCell::new(Node::new()));
        node.data = data.into();
        node.complete = false;
        'outer: loop {
            self.push(node);
            if self.combiner_lock.try_lock() {
                unsafe {
                    self.combine();
                    self.combiner_lock.unlock();
                }
                if node.complete {
                    break 'outer;
                }
            } else {
                let backoff = Backoff::new();
                loop {
                    if node.complete {
                        break 'outer;
                    }
                    backoff.snooze();
                    if backoff.is_completed() {
                        continue 'outer;
                    }
                }
            }
        }

        unsafe { ptr::read(node.data.get()) }
    }
    ```
]<code:fc-sl-lock>


Difference compared to #fc: Because we are using a concurrent priority queue, we no longer cache the node after first usage. This means that whenever a thread is trying to execute its critical section, it will have to re-insert the node into the skiplist. This is more similar to #cc-synch.

Differences compared to #cc-synch: #cc-synch utilzies a more stable mechanism to elect the next combiner by electing the start of the FIFO queue or the current executed node. Due to the complexity of a concurrent skiplist and the re-ordering nature, this is much harder to implement. However, we will discuss a possible improvement of combiner election in the next section.



=== Potential Improvements <head:fc-sl-improvements>

This section discusses some possible future improvements to #fc-sl.

==== Efficient Re-ordering

Although Skiplist offers a lock-free implementation of a priority queue, it incurs quite a few overheads due to the re-ordering. Skiplist is too general (sorting via a comparator), and suffers from high contention. Alternative solution likes Congee, which although is not lock-free, may be more efficient given that we are solely sorting via the integer value @congee_ref.

On the other hand, some relaxed version of the concurrent skiplist may be more efficient, e.g. the SprayList @spraylist_ref. It select $O(p log^3 p)$ highest nodes when poping the skiplist, where $p$ is the number of threads. By doing this, it greatly reduces the contention of concurrent poping nodes. However, since the use case in our implementation is a MPSC concurrent priority queue, directly applying SprayList is not helpful.

==== Better Combiner Election

The current combiner election policy of #fc is simple, but it is not optimal, nor predictable. Further, it is not 100% work-conserving. Consider the following scenario: One thread is combining, while some other threads try to acquire the lock. They see that there is a combiner, and will wait on the `complete` field. However, the combiner combines too many jobs, and quit combining. Now if no new threads are trying to acquire the lock, no one will be combining until one of the waiters times out and try to become the combiner.

On the other hand, the combining strategy of #cc-synch doesn't have this problem. When a combiner quit, it will either realizes that there is no remaining jobs, or notifies the next waiter to become the combiner.

Carrying this idea forward, we can adopt a similar strategy to #fc-sl. When a combiner quit, instead of simply flip the `combiner_lock`, we can check if there is any remaining jobs. If there is, we can notify the one of the waiters to become the combiner. If this fails, we can flip the `combiner_lock` to indicate that there is no combiner. This will make the lock work-conserving. 

#todo[Maybe a proof?]

If the concurrent priority queue allows the combiner to find the waiters that has the highest lock usage efficiently (for example the concurrent skiplist does), the combiner will be able to dedicate that specific thread to become the combiner, because that thread is supposed to finish its job after all other threads, which already should have high latency. 



#include "../reference.typ"