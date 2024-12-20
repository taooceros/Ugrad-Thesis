#let show-todo = false

#let not-sure = if show-todo {
    text(red, "Not Sure whether to include this")
} else {
    ""
}

#let todo(body) = if show-todo {
    text(yellow.darken(20%), [TODO: #body], weight: "bold")
} else {
    ""
}

#import "terms.typ": *