#import "utils.typ": *

= Usage Fair Delegation Styled Locks

This chapter will introduce different designs of delegation styled locks that adepts the concept of usage fairness. We start with the banning strategy,
then consider a more complex design that is inspired by the CCSynch. At last,
we introduce a new design that allows us to adopt any serialized scheduling policy
to the delegation styled locks.

We will only focus on the combining locks (e.g. #fc, #cc-synch, #dsm-synch) in this chapter, while the revision of the client-server locks can be done similarly.



#{
  let modules = (
    include "usage-fair-dlocks/banning-locks.typ",
    include "usage-fair-dlocks/naive-priority-locks.typ",
    include "usage-fair-dlocks/serialized-scheduling-locks.typ",
  )

  for module in modules {
    module
  }
}


#pagebreak(weak: true)
