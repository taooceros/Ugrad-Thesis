#show outline.entry.where(level: 1): it => {
    text(weight: "bold", it)
}

#outline(indent: auto, depth: 2)

#outline(target: figure.where(kind: figure), title: "Lists of Figures")

#outline(target: figure.where(kind: table), title: "Lists of Tables")

#outline(target: figure.where(kind: raw), title: "Lists of Code Blocks")

#pagebreak(weak: true)