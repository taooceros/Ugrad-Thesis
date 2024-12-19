#import "../template.typ": *
#show: thesis-body


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

@algorithm:fc-channel-algorithm demonstrates the lock algorithm of #fc-channel.

#figure(caption: [Lock Algorithm of #fc-channel], kind: "algorithm", supplement: [Algorithm])[
  #set align(left)
  + Write the critical section that needs to be applied sequentially to the shared object in the `data` field of your thread local publication record. The `complete` is set to `false` to indicate that there is a new critical section to be applied. If your thread local node is not marked as `active`, go to Step 5.
  + Check if the global lock is acquired. If so (there is a current active combiner), spin/wait on the `complete` field of your thread-local publication record.
  + If the lock is not acquired, try to acquire it (via `CAS` or any other atomic operations), and if successful, become a combiner. If failed, then someone else already become the combiner, you will return to Step 3.
  + Otherwise, you hold the lock and become the current combiner. Execute `combine` and then unlock the lock.
  + Insert your thread local node into the `channel`.
]<algorithm:fc-channel-algorithm>

@code:fc-channel-struct demonstrates the structure of #fc-channel. Specifically, the `waiting_nodes` is a `ConcurrentRingBuffer` (or what ever channel we want to use) that used to publish the node to the combiner. The type `(AtomicPtr<Node<I>>, u64)` includes an additional `u64` field to store the thread id of the thread that published the node, used to prevent the usage being a partial order but a total order.

#figure(caption: [Lock Structure of #fc-channel])[
  ```rust
    pub struct FCPQ<T, I, PQ, F, L>
    where
        T: Send + Sync,
        I: Send + 'static,
        PQ: SequentialPriorityQueue<UsageNode<'static, I>> + Debug,
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
]<code:fc-channel-struct>


@code:fc-channel-push demonstrates the node publishing mechanism of #fc-channel. Specifically, the `push_node` function is used to publish the node to the `waiting_nodes` (or the channel). The `push_if_unactive` function is used to check whether the node is active. If it is, the function will return immediately. Otherwise, it will publish the node to the `waiting_nodes`.

#figure(caption: [Node Publishing of #fc-channel])[
  ```rust
  fn push_node(&self, node: &Node<I>) {
      node.active = true;
      self.waiting_nodes.push((
          AtomicPtr::new(node as *const _ as *mut Node<I>),
          current().id().as_u64().into(),
      ));
  }

  fn push_if_unactive(&self, node: &mut Node<I>) {
      if node.active {
          return;
      }

      self.push_node(node);
  }
  ```
]<code:fc-channel-push>

@code:fc-channel-lock demonstrates the lock mechanism of #fc-channel, following the @algorithm:fc-channel-algorithm. The general structure is similar to the lock function of #fc.

#figure(caption: [Lock of #fc-channel])[
  ```rust
  fn lock(&self, data: I) -> I {
      let node = self.local_node.get_or(|| SyncUnsafeCell::new(Node::new()));
      node.data = data;
      node.complete = false;
      'outer: loop {
          self.push_if_unactive(node);
          if self.combiner_lock.try_lock() {
              self.combine();
              self.combiner_lock.unlock();

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

      ptr::read(node.data.get())
  }
  ```
]<code:fc-channel-lock>


@code:fc-channel-retrieve-new-nodes demonstrates the mechanism of retrieving new nodes from the `waiting_nodes` to the `job_queue`. This action will be performed by the combiner when it starts a new round of execution.



#figure(caption: [Retrieve New Nodes of #fc-channel])[
  ```rust
  fn retrieve_new_nodes(
      job_queue: &mut PQ,
      channel: &ConcurrentRingBuffer<(AtomicPtr<Node<I>>, u64), 64>,
  ) {
      if !channel.empty() {
          let iterator = unsafe { channel.iter() };

          for (node, id) in iterator {
              let node = unsafe { &*node.load_acquire() };

              job_queue.push(UsageNode {
                  usage: node.usage.load_acquire(),
                  tie_breaker: id,
                  node: node,
              });
          }
      }
  }
  ```
]<code:fc-channel-retrieve-new-nodes>

Before we proceed to the critical section execution, let's firstly consider a simplified version of #fc-channel and see why we need the additional mechanisms.

#algorithm(caption: [Possible Combining Mechanism of #fc-channel])[
  + The combiner call @code:fc-channel-retrieve-new-nodes every time it's about to execute a new critical section.
]

This version of #fc-channel seems to satisfies our goals:
+ The lock is work-conserving.
+ The lock is fair.

However, there are a very significant issue: The combiner has to cooperate with the waiter every single time a new critical section is posted. This can be expensive #footnote[Note that this is similar to but not the same as #cc-synch and #fc-sl. In those two locks, the waiter and the combiner synchronize through a lock-free data structure, while here the combiner has to manually check whether there are new waiting nodes and re-insert them into the `job_queue`.]. What's worse, experimental results shows that this version is not even close to fair (see @table:fc-channel-naive-1-stats).

One may say that we can follow the #fc and uses the node as a job posting mechanism.

#algorithm(caption: [Possible Combining Mechanism 2 of #fc-channel])[
  + The combiner call @code:fc-channel-retrieve-new-nodes every time it's about to execute a new critical section.
  + Instead of marking the node's `active` to be false, the combiner re-insert the node into the `job_queue`.
]

I intentionally ignore the part about when do we mark the node as `inactive`. Let's first see what will happen if we don't mark the node as `inactive`.

The lock will have the following issues:

+ The lock is no longer work-conserving. Because a node can be re-inserted into the top of the `job_queue`, in which when the combiner pop the next job, it will be the node that is re-inserted.
+ The lock no longer satisfies Deadlock-Freedom. It is possible that the top node that has the lowest usage is the node belongs to the combiner. However, because the combiner is trying to helping others and execute the critical section, it will not be able to post a new critical section. Therefore, the node will never contains an executable critical section.

The above issue are all due to one problem: When should we deactivate a node?

There can be possible solutions:

+ We can do a heuristic penalty for node that is not ready for execution. Each time the node is checked by the combiner and show no executable critical section, we penalize the node by increasing its usage (maybe by a constant times the average usage of the node).
+ We can use an `age` field similar to #fc to deactivate the node after a certain amount of retry.
+ We can fix the deadlock problem by deactivating the node that belongs to the combiner (or cache it and add it back to the `job_queue` after the combiner has executed the critical section).

I would like to introduces another heuristic solution that stemmed from the exponential backoff as the spinlock (@head:exponential-backoff-spinlock).

#algorithm(caption: [Exponential Buffering for #fc-channel])[
  + When combiner sees a node that is not ready for execution, it will push the node into a $L_n$ buffer.
  + If the $L_n$ buffer is full, the combiner will drain the $L_n$ buffer. If the node is ready for execution, the combiner moves the node into the `job_queue`. Otherwise, the combiner will push the node into a $L_(n+1)$ buffer.
  + Each $L_n$ buffer has twice the size of the $L_(n-1)$ buffer.
  + When $L_"Max Depth"$ buffer is full, the combiner will drain the $L_"Max"$ buffer. If the node is ready for execution, the combiner moves the node into the `job_queue`, otherwise, the node will be deactivated.
]

@code:fc-channel-buffer-backoff demonstrates the implementation where $"Max Depth"=1$. A future work is to implement the full version.

#figure(caption: [Critical Section Execution of #fc-channel])[
  ```rust
  let mut buffer = ConstGenericRingBuffer::<UsageNode<I>, TEMP_BUFFER_SIZE>::new();
  for _ in 0..H {
      let current = job_queue.pop();
      if current.is_none() { break; }
      let node = current.node;
      if !node.complete.load(Acquire) {
          ... // normal delegation execution and usage
          job_queue.push(current);
      } else {
          if buffer.is_full() {
              Self::clean_buffer(job_queue, &mut buffer);
          }
          buffer.push(current);
      }
  }

  Self::clean_buffer(job_queue, &mut buffer);
  ```
]<code:fc-channel-buffer-backoff>

@code:fc-channel-clean-buffer demonstrates the implementation of the node draining mechanism for the buffer when $"Max Depth"=1$. It will drain the buffer. If the node is ready for execution, the combiner moves the node into the `job_queue`. Otherwise, the node will be deactivated.

#figure(caption: [Clean Buffer of #fc-channel])[
  ```rust
  fn clean_buffer<const N: usize>(
      job_queue: &mut PQ,
      buffer: &mut ConstGenericRingBuffer<UsageNode<'static, I>, N>,
  ) {
      for node in buffer.drain() {
          if node.node.complete.load(Acquire) {
              node.node.usage.store_release(node.usage);
              node.node.active.store_release(false);
          } else {
              job_queue.push(node);
          }
      }
  }
  ```
]<code:fc-channel-clean-buffer>

Combining all the parts together, we use a channel and the exponential buffering mechanism to create #fc-channel, which is work-conserving, fair (essentially any kind of scheduling policy can be adopted), and has a very low overhead.

Currently, the implementation adopts a simple scheduling policy: usage-based priority scheduling. I adopt two underlying implementations:

+ A priority queue that uses a binary heap (#fc-pq-binary-heap).
+ A priority queue that uses a b-tree (#fc-pq-b-tree).


=== Future Work

There are several future works that can be done. The current implementation only realizes a exponential buffering mechanism where $"Max Depth"=1$. A future work is to implement the full version. On the other hand, the design of #fc-channel is moduler, which means we can switch the channel implementation and the scheduling policy easily. Thus, a potential future work is to try out other implementation of the channel and scheduling policy.
