#let thesis-body(content) = {
    set text(font: "Times New Roman", size: 12pt)

    show heading.where(level: 1): set text(font: "Source Sans 3", size: 25pt, weight: "semibold")

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

    set par(leading: 2em)

    content
}