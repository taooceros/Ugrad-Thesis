#show outline.entry.where(level: 1): it => {
    text(weight: "bold", it)
}

#show outline.entry: it => {
    let n = it.level - 1
    let spacing = 1.5em * n
    h(spacing) + box(width: 100% - spacing, it)
}

#outline()

#pagebreak(weak: true)