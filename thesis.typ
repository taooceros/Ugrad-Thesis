#import "frontpage.typ": *
#import "template.typ": *

#front-page([
    Usage Fair Delegation Styled Lock
], ("Hongtao Zhang",), "College", "Degree Program", [Fall 2024])

#include "copyright.typ"

#show: thesis-body

#set page(numbering: "i")

#include "acknowledgements.typ"

#include "abstract.typ"

#include "outline.typ"

#counter(page).update(1)

#set page(numbering: "1")

#set heading(numbering: "1.1 ")

#include "introduction.typ"

#include "background.typ"

#include "usage-fair-dlocks.typ"

#include "experiments.typ"

#include "future-work.typ"
