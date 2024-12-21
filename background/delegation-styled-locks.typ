#import "../utils.typ": *


== Delegation Styled Locks <head:delegation-styled-locks>

Delegation styled locks represent a synchronization paradigm where threads, instead of repeatedly attempting to acquire a lock, delegate their critical section operations to a dedicated thread. This approach aims to reduce contention and improve performance in highly concurrent scenarios. The key idea is that at any given time, a single thread (the delegate) becomes responsible for executing operations on behalf of other threads.

The main advantages of delegation locks include:
- Reduced cache coherence traffic since the delegate thread maintains exclusive access to shared data
- Better locality of reference as operations are executed sequentially by one thread
- Elimination of lock handover costs between different cores

Two primary approaches to implementing delegation locks are:
- *Combine-style*: Multiple threads combine their operations into batches for efficient processing
- *Client-server style*: A dedicated server thread handles all critical section operations



=== Combine Style Locks <head:combine-style-locks>

Combine style locks follow a pattern where one thread temporarily becomes a "combiner" that processes operations from multiple threads. When a thread wants to execute a critical section, instead of acquiring a traditional lock, it publishes its operation to a shared data structure. One of the waiting threads then becomes the combiner and executes operations on behalf of other threads.

The key components of combine style locks typically include:

- A publication list where threads register their operations
- A combining mechanism where one thread becomes the combiner
- A notification system to inform threads when their operations complete

The main benefits of this approach are:

- *Reduced Contention*: Instead of all threads competing for a lock, they coordinate through the publication mechanism
- *Improved Cache Efficiency*: The combiner thread maintains cache locality while processing multiple operations
- *Operation Batching*: Multiple operations can be processed together, amortizing synchronization costs

However, combine style locks also have some drawbacks:

- *Additional Complexity*: The implementation is more complex than traditional locks
- *Publication Overhead*: Threads must prepare and publish their operations
- *Potential Unfairness*: Some threads may wait longer if their operations are not combined

Different combining lock implementations make different trade-offs in terms of fairness, throughput, and latency. The following sections examine some notable implementations.


==== Flat Combining <head:flat-combining>

Flat Combining, introduced by Hendler et al. @flatcombining_ref, is one of the earliest and most influential combining-based synchronization techniques. The algorithm maintains a shared publication list where threads publish their intended operations, and a single thread becomes the combiner to execute operations on behalf of other threads.

The core mechanism works as follows:
- Threads add their operations to a shared publication list (a singly linked list)
- One thread acquires a global lock and becomes the combiner
- The combiner scans the publication list and executes operations for other threads
- After completion, the combiner notifies waiting threads of their results
- Periodically, the combiner removes the nodes that hasn't been combined for a long time.

For simplicity, we will skip the detail implementation of Flat Combining.

=== #cc-synch and #dsm-synch <head:cc-dsm-synch>

In constrast to Flat Combining where threads publish jobs into local nodes, #cc-synch and #dsm-synch maintains a global FIFO job list @ccsynch_ref.

The core idea behind both mechanisms is the publication record:

```c
struct Node {
    Request req;
    RetVal ret;
    boolean wait;
    boolean completed;
    Node *next;
};
```

The key differences between #cc-synch and #dsm-synch lie in how they handle publication records:

- #cc-synch contains a dummy node at the head of the list, which is used to simplify the implementation of the combining mechanism.
- #dsm-synch does not contain a dummy node, and the publication record is directly added to the list, which requires some more complex logic to handle the publication.

For sake of space, we will skip the detail implementation of #cc-synch and #dsm-synch.


// === Client-Server Styled Locks <head:client-server-styled-locks>

// #todo

// ==== RCL <head:rcl>

// @rcl_ref

// #not-sure
// ==== ffwd <head:ffwd>

// @ffwd_ref

// #not-sure

#include "../reference.typ"