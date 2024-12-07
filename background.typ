#import "utility.typ": *

= Background

#let modules = (
  "concurrency",
  "lock",
  "common-locks",
  "usage-fairness",
  "delegation-styled-locks",
  "lock-free-data-structures",
)


#{
  for module in modules {
    include "background/" + module + ".typ"
  }
}
