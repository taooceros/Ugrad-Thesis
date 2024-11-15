#import "frontpage.typ": *
#import "template.typ": *

#front-page([
    Usage Fair Delegation Styled Lock
], ("Hongtao Zhang",), "College", "Degree Program", [Fall 2024])

#include "copyright.typ"

#show: thesis-body

#set page(numbering: "i")

#include "acknowledge.typ"

#include "abstract.typ"

#include "outline.typ"

#counter(page).update(1)

#set page(numbering: "1")

#set heading(numbering: "1.")

#include "introduction.typ"
