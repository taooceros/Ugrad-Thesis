#import "../template.typ": *

== Serialized Scheduling Locks

In general, concurrent priority queue is expensive. However, if we rethink about the problem, we doesn't really need a concurrent priority queue. The thread usage is solely controlled by the combiner, which is protected by a lock (or similar mechanisms). Therefore, as long as we can ensure that the combiner knows all the thread that is waiting, we can deligate the combiner to reorder the jobs. We call this #fc-channel.

The design involves three components:
+ A combiner election policy
+ A way to allow the combiner to know there are threads waiting
+ A way to schedule the jobs

For the combiner election policy, we can use the same strategy as #fc-sl for simplicity.

=== #fc-channel

We have introduced channel in @head:channel. Specifically, we utilzies a MPSC channel to synchronize the combiner and the waiters.

We firstly introduce the layout of #fc-channel. The `combiner_lock` is used for combiner election. The `delegate` is the function that will be applied to the shared object. The `job_queue` is a priority queue that used to re-order the jobs, which is "conceptually" protected by the `combiner_lock`. The `waiting_nodes` is a channel#footnote[We specifically implements a MPSC channel as a Ring Buffer, but there can be other implementations.] that stores the nodes that are waiting for the lock. The `data` is the shared object. The `local_node` is the thread local node that is used to store the node for the current thread.


#figure(caption: [Layout of #fc-channel])[
    ```rust
    pub struct FCPQ<T, I, PQ, F, L>
    where
        T: Send + Sync,
        I: Send + 'static,
        PQ: SequentialPriorityQueue<UsageNode<'static, I>>,
        F: Fn(&mut T, I) -> I,
        L: RawMutex,
    {
        combiner_lock: CachePadded<L>,
        delegate: F,
        job_queue: SyncUnsafeCell<PQ>,
        waiting_nodes: ConcurrentRingBuffer<(AtomicPtr<Node<I>>, u64), 64>,
        data: SyncUnsafeCell<T>,
        local_node: ThreadLocal<SyncUnsafeCell<Node<I>>>,
    }
    ```
]


The algorithm follows the following steps:

+ Write the critical section that needs to be applied sequentially to the shared object in the `data` field of your thread local publication record. The `complete` is set to `false` to indicate that there is a new critical section to be applied.
+ Push your thread local publication record into the skiplist.
+ Check if the global lock is acquired. If so (there is a current active combiner), spin/wait on the `complete` field of your thread-local publication record.
+ If the lock is not acquired, try to acquire it (via `CAS` or any other atomic operations), and if successful, become a combiner. If failed, then someone else already become the combiner, you will return to Step 3.
+ Otherwise, you hold the lock and become the current combiner. Execute `combine` and then unlock the lock.

