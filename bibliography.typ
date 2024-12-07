
#let bib_state = counter("bib_state")

#bib_state.step()

#context {
  if bib_state.get() == bib_state.final() [
    #bibliography("lit.bib", style: "association-for-computing-machinery", title: "References")
  ]
}

