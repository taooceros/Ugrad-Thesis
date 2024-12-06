= Usage Fair Delegation Styled Locks

#{
  let modules = (
    "banning-locks.typ",
    "naive-priority-locks.typ",
    "serialized-scheduling-locks.typ"
  )

  for module in modules {
    include "usage-fair-dlocks/" + module
  }
}


#pagebreak(weak: true)
