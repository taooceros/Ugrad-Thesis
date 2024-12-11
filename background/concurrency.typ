= Concurrency, Synchronization & Mutual Exclusion <head:concurrency>

In modern computing systems, concurrency is fundamental to achieving high performance and resource utilization. Concurrent programming allows multiple computations to progress simultaneously, whether through true parallelism on multiple processors or through interleaved execution on a single processor. However, concurrent execution introduces challenges when multiple threads or processes need to access shared resources.

Synchronization mechanisms are essential tools that help coordinate concurrent operations and maintain program correctness. These mechanisms ensure that concurrent accesses to shared resources follow a proper order and maintain consistency. Without synchronization, concurrent access to shared data can lead to race conditions, where the program's outcome becomes unpredictable and depends on the precise timing of operations.

== Race Conditions and Data Races

Race conditions and data races are two distinct but related concurrency hazards. A data race occurs when two or more threads access the same memory location concurrently, and at least one of these accesses is a write operation, without proper synchronization. For example, if two threads simultaneously increment a shared counter (`count++`), a data race can occur because this operation actually involves three steps: reading the value, incrementing it, and writing it back. The final value might be incorrect if the threads interleave these steps.

A race condition is a broader concept that occurs when the correctness of a program depends on the relative timing or interleaving of multiple operations. While data races are a common cause of race conditions, race conditions can exist even in programs free of data races. Consider a check-then-act sequence: checking if a file exists and then opening it. Even with properly synchronized individual operations, a race condition exists if another process deletes the file between the check and the open operation.

== Mutual Exclusion

Mutual exclusion is a core concept in concurrent programming that ensures only one thread can access a critical section at a time. A critical section is a region of code that accesses shared resources and must be executed atomically to maintain consistency. The classic example is a bank account balance: if two threads simultaneously try to modify the balance, concurrent access without mutual exclusion could lead to lost updates or incorrect final values.

Various mechanisms exist to implement mutual exclusion, with locks being one of the most common approaches. Locks provide a way for threads to coordinate access to shared resources by acquiring exclusive access before entering a critical section and releasing it afterward. The following sections explore different lock implementations, their characteristics, and the trade-offs they present in terms of performance, fairness, and complexity.

#include "../reference.typ"
