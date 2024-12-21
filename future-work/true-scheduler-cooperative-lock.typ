== Transparent Delegation Styled Locks

One of the fundamental issues with delegation styled locks is that it offers a different set of API compared to the traditional locks. Despite the fact that delegation styled lock may offer various performance benefits, it is hard to port existing code to use delegation styled lock. What's worse, it generally requires developers to re-design the access pattern of the data structure, which is not trivial.

TCLocks showed that it is possible to design a transparent delegation styled lock that offers the same set of API as the traditional locks @tclocks_ref. The idea is clean and simple: a stack of a thread, combined with all the register, should capture all the execution frame of the specific thread. In such, besides some subtle problems (e.g. interrupt), we should be able to store the execution frame of a thread with a traditional lock API. This allows people to use delegation styled lock without changing the code massively.

== Asynchronous Programming <head:asynchronous-programming>

Let me briefly switch the topic and introduce asynchronous programming. We will see the analogy between the stackful coroutine and how TCLocks works.

=== Stackful Coroutines

Stackful coroutines, particularly as implemented in Go (known as "goroutines"), represent a powerful abstraction for concurrent programming. Unlike traditional threads that require significant memory overhead, goroutines are lightweight and can be created with just a few kilobytes of stack space. They are called "stackful" because each coroutine maintains its own stack, allowing them to be suspended and resumed at any point in their execution, even deep within a call chain.

In Go's implementation, goroutines are multiplexed onto a smaller number of operating system threads by the Go runtime scheduler. This M:N scheduling model (mapping M goroutines to N OS threads) provides excellent scalability, allowing programs to spawn thousands or even millions of goroutines efficiently. When a goroutine performs a blocking operation (like channel communication or I/O), the runtime can automatically switch to executing other goroutines, making efficient use of system resources without explicit programmer intervention.

The stackful nature of these coroutines provides several key advantages over stackless alternatives:

+ *Deep Call Chain Support*: Stackful coroutines can yield from any point in the call stack, even from deeply nested function calls. This is particularly valuable when working with recursive algorithms or complex asynchronous operations.

+ *Natural Programming Model*: Developers can write concurrent code that looks and feels like sequential code, without explicitly managing continuation points or breaking functions into multiple parts.

+ *Efficient Context Switching*: The runtime can perform context switches between coroutines with minimal overhead, as it only needs to save and restore a small amount of state compared to OS-level thread switches.

Go's implementation includes sophisticated features like:

+ *Stack Growth*: Goroutines start with a small stack (typically 2KB) that can grow dynamically as needed, up to a configurable maximum.
+ *Work Stealing*: The scheduler implements work stealing to balance load across multiple OS threads, improving CPU utilization.
+ *Preemption*: Recent versions of Go include asynchronous preemption, allowing the runtime to interrupt long-running goroutines to maintain system responsiveness.

This model has proven particularly effective for building highly concurrent network services and distributed systems, where the ability to handle many concurrent operations efficiently is crucial. The combination of stackful coroutines with channels creates a powerful programming model that simplifies the development of concurrent applications while maintaining high performance.


=== Connection to TCLocks and Stackful Coroutines

Now if we look back at the design of TCLocks, we can see that it essentially borrow how people control the execution context of a stackful coroutine, but operating on the thread level.

+ *Context Management*: Like stackful coroutines, TCLocks maintain the full execution context of each thread, including the stack. When a waiter delegates its critical section to the combiner, the entire stack context is preserved, allowing the combiner to execute the critical section from any point in the call chain. This is conceptually similar to how goroutines maintain their own stack and can be suspended at any point.

+ *Transparent Context Switching*: TCLocks perform lightweight context switches to execute critical sections on behalf of waiters, similar to how Go's runtime switches between goroutines. However, while Go's scheduler makes scheduling decisions based on factors like I/O and time slices, TCLocks' context switches are driven by lock acquisition patterns.

+ *Stack-based Execution*: Both systems leverage the natural stack-based execution model. In TCLocks, the waiter's stack contains all the necessary information for the critical section execution, eliminating the need for explicit packaging of critical sections. This is analogous to how stackful coroutines can maintain their entire call chain state without manual continuation management.

The key innovation in TCLocks is applying these coroutine-like properties to lock delegation:
+ Instead of requiring explicit critical section packaging (as in previous delegation-based locks)
+ TCLocks automatically capture and transfer the execution context
+ This enables transparent execution of critical sections on behalf of waiting threads
+ All while maintaining the full call chain context, similar to how stackful coroutines operate

Now once we have see the analogy between TCLocks and stackful coroutines, one may think can we apply the same idea to a stackless coroutine?

=== Stackless Coroutine and async/await <head:async-await>

Stackless coroutines, unlike their stackful counterparts, do not maintain their own stack. Instead, they transform the program into a state machine where each suspension point becomes a different state. This transformation is typically done by the compiler, which converts asynchronous functions into a series of synchronous steps that can be suspended and resumed.

The most common form of stackless coroutines in modern programming is the async/await pattern. In languages like Rust, async functions are transformed into state machines at compile time. Let's look at a simple example:

```rust
async fn process_data(data: &mut Data) -> Result<(), Error> {
    let result = compute_something(data).await;
    update_data(data, result).await;
    Ok(())
}
```

When compiled, this function is transformed into roughly the following state machine:
1. Initial state: Start execution
2. State 1: Waiting for `compute_something`
3. State 2: Waiting for `update_data`
4. Final state: Return result

The key differences between stackless and stackful coroutines are:

+ *Memory Management*: Stackless coroutines only need to store the minimal state required for their current suspension point, rather than maintaining a full stack.

+ *Suspension Points*: Stackless coroutines can only suspend execution at well-defined points (typically marked with `.await`), while stackful coroutines can suspend anywhere.

+ *Compiler Support*: Stackless coroutines require significant compiler support to transform functions into state machines, while stackful coroutines can be implemented primarily in the runtime.

The async/await pattern brings several advantages:
+ Lower memory overhead per coroutine
+ Predictable suspension points
+ Explicit handling of asynchronous operations
+ Compiler guarantees about data races and lifetime issues

However, it also has limitations:
+ Cannot suspend from arbitrary call points
+ Requires explicit marking of async functions
+ Creates a "split" in the codebase between sync and async code
+ May generate larger code due to state machine transformations

This tradeoff between flexibility and overhead makes stackless coroutines particularly suitable for scenarios where:
+ The number of concurrent operations is very high
+ Suspension points are well-defined and limited
+ Memory efficiency is crucial
+ Compile-time guarantees are important

=== Async Locks

Since stackless coroutine will create a suspend point at every `.await`, it essentially also capture the execution context of the task at every single break point. However, none of the state of art async locks employs the idea of delegation styled lock. Most of them just do what a traditional lock does, and incooperate with some additional mechanism to make it non-blocking under the async runtime. This makes most async locks less performant than their counterpart under the synchronous context. Can we do better?

== (True) Scheduler Cooperative Lock

At the very end of the thesis, I want to propose something that incoperate all the above ideas. Specifically, SCL uses the name of "Scheduler Cooperative Lock" to refer to the lock. However, SCL didn't really cooperate with the scheduler, but rather just tries to achieve a similar goal as the scheduler.

Therefore, one may ask, can we do something that really cooperate with the scheduler?

One problem here is that we know context switch is expensive, and we want to avoid context switch as much as possible. However, in order to really cooperate with the scheduler, we need to do context switch.

However, how about we make it cheaper? One of the main motivation of using coroutine (regardless of whether it is stackful or stackless) is to make the context switch cheaper. Thus, people can create thousands of coroutines without worrying about the overhead of switching among them.

Carrying this idea forward, we can create a async lock that can cooperate with the scheduler. We will only consider the stackless coroutine here. Assuming we are under an work-stealing scheduler, when a task is waiting for a lock, it suspends itself and switch to the current runner that is holding the lock. Then when the runner is done, it can check whether there are any tasks waiting for the lock. If there is, it can switch to the next task, and since critical section is generally more important to the overall performance, it can switch the non-critical section to another runner, and continue to execute the critical section for the specific lock.

I call this idea "scheduler aware lock". This is not something new, as `mutex` essentially use a park/unpark mechanism to achieve a similar goal (to not wasting CPU cycles when waiting for a lock). However, one complaint of `mutex` is that park/unpark is generally slow, which hurts the performance of the lock. By connecting with the idea of delegation styled lock, we can achieve a lock that is both performant and scheduler cooperative.
