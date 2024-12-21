== Common Lock Primitive Implementations <head:common-locks>

In this section, we will review some common lock primitive implementations.

=== Naive Spinlock <head:naive-spinlock>


A spinlock is one of the simplest lock implementations, where waiting threads actively poll (or "spin") on a memory location until they can acquire the lock. The core idea is to use atomic operations to modify a shared variable that represents the lock state.

A basic spinlock can be implemented using a single atomic boolean:

```c
typedef struct {
    atomic_bool locked;
} spinlock_t;

void spin_lock(spinlock_t *lock) {
    while (atomic_exchange(&lock->locked, true)) {
        // Spin until we acquire the lock
    }
}

void spin_unlock(spinlock_t *lock) {
    atomic_store(&lock->locked, false);
}
```

Spinlocks have several characteristics that make them suitable for specific scenarios:

+ *Low Latency*: When contention is low and critical sections are very short, spinlocks can be more efficient than locks that involve thread scheduling.
+ *Simple Implementation*: The basic version requires just a single atomic variable and a few instructions.
+ *No Scheduler Interaction*: Useful in contexts where thread blocking is not possible, such as in interrupt handlers.

However, spinlocks also have significant limitations:

+ *CPU Intensive*: Spinning threads consume CPU cycles while waiting
+ *Priority Inversion*: A low-priority thread holding the lock can prevent a high-priority thread from running
+ *Energy Inefficient*: Continuous spinning wastes power, particularly important in mobile devices


=== Pthread Spinlock (test and test lock) <head:pthread-spinlock>

The pthread spinlock implementation represents a more sophisticated approach to spinlocks, using a "test-and-test-and-set" pattern (@code:pthread-spinlock). This pattern reduces memory bus contention by first reading the lock value before attempting the more expensive atomic exchange operation. When multiple threads are spinning, they primarily spin on cached reads rather than constantly hammering the memory bus with atomic operations.

The implementation includes a busy-wait loop with explicit memory ordering semantics and CPU-specific optimizations. It uses either atomic exchange or compare-and-swap (CAS) operations depending on the platform's capabilities, and includes a spin hint (`atomic_spin_nop()`) to improve efficiency on modern processors.

#figure(caption: "Pthread Spinlock Implementation")[
    ```c
    int
    __pthread_spin_lock (pthread_spinlock_t *lock)
    {
    int val = 0;
    #if ! ATOMIC_EXCHANGE_USES_CAS
    if (__glibc_likely (atomic_exchange_acquire (lock, 1) == 0))
        return 0;
    #else
    if (__glibc_likely (atomic_compare_exchange_weak_acquire (lock, &val, 1)))
        return 0;
    #endif
    do
    {
        do
        {
            atomic_spin_nop ();
            val = atomic_load_relaxed (lock);
        }
        while (val != 0);
    }
    while (!atomic_compare_exchange_weak_acquire (lock, &val, 1));
    return 0;
    }
    ```
]<code:pthread-spinlock>



=== Exponential Backoff Spinlock <head:exponential-backoff-spinlock>

An exponential backoff spinlock improves upon the basic spinlock by introducing delays between lock acquisition attempts @aomp_ref. When contention occurs, threads wait for increasingly longer periods before retrying, reducing CPU usage and memory bus contention.

A simple implementation might look like this:

```c
typedef struct {
    atomic_bool locked;
} backoff_spinlock_t;

void backoff_spin_lock(backoff_spinlock_t *lock) {
    unsigned int backoff = 1;
    
    while (atomic_exchange(&lock->locked, true)) {
        // Exponential backoff
        for (unsigned int i = 0; i < backoff; i++) {
            atomic_spin_nop();
        }
        // Double the backoff period, up to a maximum
        backoff = min(backoff << 1, MAX_BACKOFF);
    }
}

void backoff_spin_unlock(backoff_spinlock_t *lock) {
    atomic_store(&lock->locked, false);
}
```

The key advantages of exponential backoff include:

+ *Reduced Contention*: By spacing out retry attempts, it reduces pressure on the memory bus
+ *Better Energy Efficiency*: Less aggressive spinning means lower power consumption
+ *Improved Scalability*: Performance degrades more gracefully under high contention

The main tradeoff is slightly increased latency for uncontested lock acquisitions, though this is usually negligible compared to the benefits under contention.


// === Pthread Mutex <head:mutex>



// === Ticket Lock <head:ticket-lock>

// === MCS & K42 variant <head:mcs-lock>

#include "../reference.typ"