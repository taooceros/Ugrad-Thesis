== Common Concurrent Data Structures <head:common-concurrent-data-structures>

// === Linked List <head:lock-free-linked-list>

// @aomp_ref

// === Skip-List <head:lock-free-skip-list>

// @aomp_ref @skiplist_ref

// === Priority Queue <head:lock-free-priority-queue>

// @aomp_ref

=== Channel <head:channel>

Channel is a fundamental concurrent primitive that enables safe communication between threads. It provides a way for threads to pass messages to each other without sharing memory directly, following the principle "don't communicate by sharing memory; share memory by communicating." Channels can be thought of as pipes that connect concurrent threads, where one thread can send data through one end, and another thread can receive it from the other end.

Modern programming languages like Go and Rust have made channels a central part of their concurrency models. Channels can be either bounded (with a fixed capacity) or unbounded, and they can be synchronous (where sends block until there's a receiver) or asynchronous (where sends can proceed if there's buffer space available). This flexibility makes channels particularly useful for implementing various concurrent patterns, including producer-consumer relationships, fan-out/fan-in workflows, and job distribution systems.


One of the most common implementation of channel is ring buffer, which is a circular buffer that allows for efficient data transfer between threads @ringbuffer_ref. 

#pagebreak(weak: true)

#include "../reference.typ"