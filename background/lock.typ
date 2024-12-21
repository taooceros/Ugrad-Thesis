== Locks <head:locks>

Locks are fundamental synchronization primitives that protect shared resources in concurrent programs by ensuring mutual exclusion. When a thread acquires a lock, it gains exclusive access to the protected resource, preventing other threads from accessing it simultaneously. This exclusivity helps maintain data consistency and prevents race conditions.

A basic lock interface typically provides two core operations:
+ *lock()*: Acquire exclusive access to the protected resource
+ *unlock()*: Release the exclusive access, allowing other threads to acquire the lock

For example, a simple critical section protected by a lock looks like:

```c
pthread_mutex_lock(&mutex);
// Critical section: only one thread can execute this at a time
shared_data.modify();
pthread_mutex_unlock(&mutex);
```

While conceptually simple, lock implementation and usage significantly impact program performance and correctness. Key considerations include:

+ *Fairness*: How the lock arbitrates between multiple waiting threads
+ *Performance*: The overhead of lock acquisition and release
+ *Progress Guarantees*: Whether threads are guaranteed to eventually acquire the lock
+ *Memory Ordering*: How lock operations affect visibility of shared memory operations

Modern locks often implement sophisticated mechanisms to address these concerns:

+ *Spinning vs Blocking*: Whether threads actively wait or yield the processor while waiting
+ *Queue-based Organization*: How waiting threads are organized and scheduled
+ *Delegation*: Whether critical sections can be executed by a designated thread
+ *Locality*: How lock operations affect cache coherence and memory traffic

The choice of lock implementation can dramatically affect application performance, particularly under high contention when many threads compete for the same lock. This has led to the development of various specialized locks, each optimized for different usage patterns and requirements.

#include "../reference.typ"
