= Abstract

In multi-threaded enviroment, resources sharing and synchronization is an important topic. Locks are the most common synchronization technique for such problem. There are two fundamental properties a good lock want to achieve: 1) performance 2) fairness. Specifically, latest research emphasizes the need of usage fairness. Threads are not only allowed to enter the lock with different frequency, but also may use the lock for different amount of time.

On the first glance, it seems that these two properties are contradictory. Can we have a high performance lock while providing usage fairness?

To answer the above question, this dissertation proposes that lock should be designed as delegation: thread should not execute their critical section directly, but delegate the execution to a combiner. This thesis shows that under the setting of delegation styled lock, we can have a usage-fair lock without sacrificing performance. I introduce two types of fair delegation styled locks: 1) non-work-conserving `FC-Ban` and `CC-Ban` 2) work-conserving `FC-PQ`. My evaluation shows that all three of them can achieve high throughput and usage fairness simultaneously, while `FC-PQ` outperforms the other two when the lock is heavily contended while threads are having large non-critical section.


#pagebreak(weak: true)