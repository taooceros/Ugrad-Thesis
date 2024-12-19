#import "template.typ": *

= Charateristics & Experiments

In this section, we will present the characteristics of the locks and the experiments results. Specifically, we focus on three aspects: Throughput (@head:experiment-throughput), Fairness (@head:experiment-fairness), and Latency (@head:experiment-latency).

The experiments are conducted on Cloudlab (c220g2), with the following specifications:

#figure(caption: "Hardware Specifications")[
  #table(columns: 2)[CPU][Two Intel E5-2630 v3 8-core CPUs at 2.40 GHz (Haswell EP)][RAM][160GB ECC Memory (10x 16 GB DDR4 2133 MHz dual rank RDIMMs)][Disk][One Intel DC S3500 480 GB 6G SATA SSDs]
]<table:experiment-hardware>

== Throughput <head:experiment-throughput>

We evaluate the performance of various locks under a synthetic workload to measure their scalability and efficiency. Each thread attempts to acquire a lock, increment a shared counter, and release the lock. The throughput, defined as the total number of operations completed, provides a measure of the lock's ability to handle concurrent threads.

#figure(caption: "Throughput with 0 and 1000 non-critical section iterations")[
  #image("images/throughput-1000-3000-0-1000.svg")
]<figure:throughput-1000-3000-0-1000>

@figure:throughput-1000-3000-0-1000 demonstrates the throughput of different locks under different thread counts. The thread count increases from 2 to 32. The threads are groupped into two groups: 
- Group 1 will acquire the lock and execute the critical section for 1000 iterations, and then release the lock.
- Group 2 will wait for the lock and then execute the critical section for 3000 iterations, and then release the lock.

In the left plot, thread will immediately try to acquire the lock again after releasing it. In the right plot, thread will wait for 1000 iterations before trying to acquire the lock again.

#figure(caption: "Throughput with 10000 non-critical section iterations")[
  #image("images/throughput-1000-3000-10000.svg")
]<figure:throughput-1000-3000-10000>

@figure:throughput-1000-3000-10000 demonstrates the throughput when threads have a relatively large non-critical section (10000 iterations).

The experiment demonstrate the comparison of throughput for each locks with varying size of non-critical section. The result shows that the size of non-critical section has minimal impact on the overall throughput for all locks but `Mutex` and `U-SCL` until hitting a large enough non-critical section (10000) which has the possibility that all threads would not try to acquire the critical section for a certain amount of time. These performance degration is recovered when the contention increases (thread number increase).

`Mutex` presents the best behavior when size of non-critical section is small, which aligns the best with its `spin-and-wait` strategy. `U-SCL` suffers from any non-critical section because of the presence of lock slice.

#u-scl demonstrate extrodinary performance when the thread number is 2, which aligns with its special optimization toward 2 thredas.

Specifically, the only case when `SpinLock` outperform other locks are when we have non-critical section size 10000 with two threads and size 100000 with two/four/eight threads. In these configuration, there might be some times in which all threads would not try to acquire the lock, in which the delegation-styled locks may fail to combine as it is the combiner may be the only one active in executing the critical section.

In most other configuration, `FlatCombining` outperform other locks, which reproduces the high performance mentioned in the paper presenting `CC-Synch`. They mentioned that `FlatCombining` is providing extrodinary performance when the critical section is small (around 1000 iterations). These performance difference may due to the fact that the current implementation of `FlatCombining` utilizes the exponential backoff strategy, while `CC-Synch`/`DSM-Synch` does not.

#fc-sl demonstrates bad performance because the overhead of skiplist, but still outperform other locks that doesn't employ delegation strategy.

On the other hand, we can see that the banning strategy is costing performance degradation when the non-critical section is large. In @figure:throughput-1000-3000-10000, we can see that #fc-banning and #cc-synch-banning demonstrate suboptimal performance compared to #fc, #cc-synch, #dsm-synch, #fc-sl, #fc-pq-b-tree and #fc-pq-binary-heap when the number of threads are small.

Overall, we see that all of our delegation-styled locks outperform other locks that doesn't employ delegation strategy.

== Fairness <head:experiment-fairness>

One of the focus of this thesis is to improve the fairness of the locks while preserving the performance through delegation strategy. We evaluate the fairness of the locks by measuring the variance of the execution time of each thread.


== Latency <head:experiment-latency>

#include "reference.typ"

#pagebreak(weak: true)
