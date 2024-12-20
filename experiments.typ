#import "template.typ": *

#show: thesis-body

= Characteristics & Experiments <head:experiment>

In this section, we will present the characteristics of the locks and the experimental results. Specifically, we focus on three aspects: Throughput (@head:experiment-throughput), Fairness (@head:experiment-fairness), and Latency (@head:experiment-latency).

The experiments are conducted on Cloudlab (c220g2), with the following specifications:

#figure(caption: "Hardware Specifications")[
  #table(columns: 2)[CPU][Two Intel E5-2630 v3 8-core CPUs at 2.40 GHz (Haswell EP)][RAM][160GB ECC Memory (10x 16 GB DDR4 2133 MHz dual rank RDIMMs)][Disk][One Intel DC S3500 480 GB 6G SATA SSDs]
]<table:experiment-hardware>

== Throughput <head:experiment-throughput>

We evaluate the performance of various locks under a synthetic workload to measure their scalability and efficiency. Each thread attempts to acquire a lock, increment a shared counter, and release the lock. The throughput, defined as the total number of operations completed, provides a measure of the lock's ability to handle concurrent threads.

#figure(caption: "Throughput with 0 and 1000 non-critical section iterations")[
  #image("images/throughput-1000-3000-0-1000.svg")
]<figure:throughput-1000-3000-0-1000>

@figure:throughput-1000-3000-0-1000 demonstrates the throughput of different locks under different thread counts. The thread count increases from 2 to 32. The threads are grouped into two groups: 
- Group 1 will acquire the lock and execute the critical section for 1000 iterations, and then release the lock.
- Group 2 will wait for the lock and then execute the critical section for 3000 iterations, and then release the lock.

In the left plot, thread will immediately try to acquire the lock again after releasing it. In the right plot, thread will wait for 1000 iterations before trying to acquire the lock again.

#figure(caption: "Throughput with 10000 non-critical section iterations")[
  #image("images/throughput-1000-3000-10000.svg")
]<figure:throughput-1000-3000-10000>

@figure:throughput-1000-3000-10000 demonstrates the throughput when threads have a relatively large non-critical section (10000 iterations).

The experiment demonstrate the comparison of throughput for each locks with varying size of non-critical section. The result shows that the size of non-critical section has minimal impact on the overall throughput for all locks but `Mutex` and `U-SCL` until hitting a large enough non-critical section (10000) which has the possibility that all threads would not try to acquire the critical section for a certain amount of time. This performance degradation is recovered when the contention increases (thread number increase).

`Mutex` presents the best behavior when size of non-critical section is small, which aligns the best with its `spin-and-wait` strategy. `U-SCL` suffers from any non-critical section because of the presence of lock slice.

#u-scl demonstrates extraordinary performance when the thread number is 2, which aligns with its special optimization toward 2 threads.

Specifically, the only cases where `SpinLock` outperforms other locks are when we have non-critical section size 10000 with two threads and size 100000 with two/four/eight threads. In these configuration, there might be some times in which all threads would not try to acquire the lock, in which the delegation-styled locks may fail to combine as it is the combiner may be the only one active in executing the critical section.

In most other configuration, `FlatCombining` outperforms other locks, which reproduces the high performance mentioned in the paper presenting `CC-Synch`. They mentioned that `FlatCombining` is providing extraordinary performance when the critical section is small (around 1000 iterations). These performance differences may be due to the fact that the current implementation of `FlatCombining` utilizes the exponential backoff strategy, while `CC-Synch`/`DSM-Synch` does not.

#fc-sl demonstrates poor performance due to the overhead of skiplist, but still outperforms other locks that doesn't employ delegation strategy.

On the other hand, we can see that the banning strategy causes performance degradation when the non-critical section is large. In @figure:throughput-1000-3000-10000, we can see that #fc-banning and #cc-synch-banning demonstrate suboptimal performance compared to #fc, #cc-synch, #dsm-synch, #fc-sl, #fc-pq-b-tree and #fc-pq-binary-heap when the number of threads are small.

Overall, we see that all of our delegation-styled locks outperform other locks that doesn't employ delegation strategy.

== Fairness <head:experiment-fairness>

One of the focus of this thesis is to improve the fairness of the locks while preserving the performance through delegation strategy. We evaluate the fairness of the locks by measuring the variance of the execution time of each thread.

#figure(caption: "Fairness with 0 and 1000 non-critical section iterations")[
  #image("images/fairness-line-1000-3000-0-1000.svg")
]<figure:fairness-line-1000-3000-0-1000>

#figure(caption: "Fairness with 10000 non-critical section iterations")[
  #image("images/fairness-box-1000-3000-0-1000.svg")
]<figure:fairness-box-1000-3000-0-1000>

@figure:fairness-line-1000-3000-0-1000 and @figure:fairness-box-1000-3000-0-1000 demonstrates the fairness of the locks with 16 threads contending. Left plot shows the fairness of the locks with 0 iterations of non-critical section. Right plot shows the fairness of the locks with 1000 iterations of non-critical section.


We can see that most delegation styled lock has demonstrated (amortized) acquisition fairness. The throughput comparison of threads are proportional to the critical section. On the other hand, #mutex and #spinlock has demosntrated the potential to starve thread, which is expected. As noted in previous work, the disproportional workload will be amplified with non-fair lock @scheduler_coop_locks_ref.

The fair variant of delegation styled locks based on banning strategy have demonstrate the fairness guarantee comparable to _U-SCL_, while maintaining high performance. On the other hand, the current implmentation fails to provide fairness guarantee if only two threads are contending for the lock, while `U-SCL` is able to both perform well and provide fairness. The reason is not so clear yet, but potential reason include:

1. Combiner are unable to insert their work to the job queue when it is combining, which might yield additional unfairness if the thread with smaller critical section becomes the combiner.
2. The current banning algorithm different than the one use in `U-SCL`, which bans every thread even though they hasn't entered the critical section for a while. This is probably not a good practice and should be fixed.

Other fair variant of delegation styled locks, such as `FC_PQ_BTree`/`FC_PQ_BHeap` and `FC_SL` also demonstrate significant unfairness when only two threads are competing. The major reason for these unfainess is likely to attribute to the small contention, which makes it hard for the coordinator to reorder the job sequence.

Both of these priority queue based fair variant are using simple heuristic similar to `CFS` by counting the usage of each thread toward the lock and reorder jobs. When the thread number is low, it is unlikely that the waiter can insert its second job before the combiner decides to switch to job from another threads, which yield to the unfairness.


== Latency <head:experiment-latency>

In this section, we will present the latency of the locks. We will measure the latency of the locks by measuring the time it takes for a thread to acquire the lock and execute the critical section. Now the thread will only execute a very short critical section (1 iteration) and then release the lock.

#figure(caption: "Latency of 16 threads contending for the lock")[
  #image("images/latency-single-addition-all.svg")
]<figure:latency-all>

@figure:latency-all demonstrates the latency of the locks with 16 threads contending for the lock. The thread will only execute a very short critical section (1 iteration) and then release the lock. In each of the plot, we have more than 10M data points (except for #fc-sl).

We can see that the latency of #fc-sl, although it is supposed to be the fairest, has the largest tail latency.

#figure(caption: "Latency of 16 threads (5% - 95% percentile)")[ 
  #image("images/latency-central-no-fc-sl.svg")
]<figure:latency-central-no-fc-sl>

@figure:latency-central-no-fc-sl demonstrates the latency truncating some of the tail latency and ignore #fc-sl. We can see that #fc-channel demonstrates relatively worse performance, probably due to the additional re-ordering from the combiner as the critical section is small. Other delegation styled locks demonstrates similar latency results.

=== Future Work <head:latency-future-work>

There are several important measurement that we should be doing to fully understand the behavior of the locks.

1. A larger critical section size should be characterized.
2. Variable size of critical section should be characterized (and the correlation between critical section size and the latency distribution).
3. Variable size of non-critical section should be characterized (and the correlation between non-critical section size and the latency distribution).
4. The comparison between combiner and non-combiner should be characterized.

Further, we should integrate with the analysis for a scheduler, as a fair lock should advocate similar behavior as a scheduler.

== Additional Experiments for Future <head:future-work-additional>

For a more comprehensive analysis, additional experiments that domonstrate end to end performance of the locks should be conducted.

- A linked list implemented with different locks.
- A hash table implemented with different locks.
- A Stack/Queue implemented with different locks.
- Comparison with State of Art concurrent data structures.


#include "reference.typ"

#pagebreak(weak: true)
