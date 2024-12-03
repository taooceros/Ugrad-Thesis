#let thesis-body(content) = {
    set text(size: 12pt)

    show heading.where(level: 1): set text(font: "Source Sans 3", size: 25pt, weight: "medium")
    show heading.where(level: 2): set text(size: 18pt)

    set page(margin: (top: 2in, bottom: 2in, left: 1.5in, right: 1.5in), header: [
        #h(1fr) #counter(page).display("i")
    ])

    pagebreak(weak: true)

    show heading.where(level: 1): it => {
        v(5em)
        set align(right)
        it.body
        v(1em)
    }

    show heading.where(level: 2): it => {
        v(0.5em)
        
        [#numbering(it.numbering, ..counter(heading).get()) #it.body]
    }

    show outline: set par(leading: 1.5em)

    content

    bibliography("lit.yaml", style: "association-for-computing-machinery")
}