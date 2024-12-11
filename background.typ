#import "utility.typ": *

= Background

#let modules = (
  include "background/concurrency.typ",
  include "background/lock.typ",
  include "background/common-locks.typ",
  include "background/usage-fairness.typ",
  include "background/delegation-styled-locks.typ",
  include "background/lock-free-data-structures.typ",
)


#{
  for module in modules {
    module
  }
}
