#import "utils.typ": *

= Background <head:background>

#let modules = (
  include "background/concurrency.typ",
  include "background/lock.typ",
  include "background/common-locks.typ",
  include "background/usage-fairness.typ",
  include "background/delegation-styled-locks.typ",
  include "background/common-concurrent-data-structures.typ",
)


#{
  for module in modules {
    module
  }
}
