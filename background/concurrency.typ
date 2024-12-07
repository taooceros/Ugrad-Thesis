== Concurrency, Synchronization & Mutual Exclusion <head:concurrency>

In modern computing systems, concurrency is fundamental to achieving high performance and resource utilization. When multiple computations need to execute, they can be interleaved on a single processor to create the illusion of simultaneous execution, or run truly in parallel across multiple processors. This interleaving allows the processor to switch between different tasks when one is blocked or waiting, making efficient use of system resources.

These interleaved executions introduce challenges when multiple threads or processes need to access shared resources. People make assumptions about results of previous operations. However, the interleaving can cause violations of these assumptions, leading to incorrect program behavior.

Synchronization is the art of coordinating concurrent operations and maintaining program correctness. These mechanisms ensure that concurrent accesses to shared resources follow a proper order and maintain consistency. Without synchronization, concurrent access to shared data can lead to race conditions, where the program's outcome becomes unpredictable and depends on the precise timing of operations.

One of the most common synchronization mechanisms is to adopt _Mutual Exclusion_. _Mutual Exclusion_ reconstructs the assumptions by disallowing concurrent access to the shared resource, and thus recovers the sequential behavior. The set of operations that needs to be protected by mutual exclusion is called a _critical section_.


There are various mechanisms to implement mutual exclusion, such as hardware provided atomic instructions, locks, semaphores, or transactional memory. Locks are one of the most commonly used mechanisms to implement achieve mutual exclusion. Only a single owner is allowed to own the lock at a time. By forcing threads to acquire the lock before entering the critical section, we can ensure that the critical section is executed sequentially without interference from other threads.

#include "../bibliography.typ"
