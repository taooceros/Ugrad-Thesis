#import "utils.typ": *
#import "@preview/codly:1.1.1": *
#import "@preview/codly-languages:0.1.3": *
#import "@preview/showybox:2.0.3": showybox

#let front-page(title, authors, college, degree-program, date) = {
  set text(size: 12pt)
  set page(margin: 1in)
  v(4em)
  align(
    center,
    {
      heading(outlined: false, title)

      v(4em)
      [
        by
      ]
      v(1em)

      authors.join(", ")

      v(2em)

      [
        A thesis submitted in partial fulfillment of \
        the requirements for the degree of
      ]

      v(3em)

      [
        Bachelor of Science

        (Computer Science)

        at the

        UNIVERSITY OF WISCONSIN-MADISON
      ]

      v(3em)

      date
    },
  )

  v(1fr)

  [
    This thesis was completed under the direction of:\
    #h(2em) Remzi Arpaci-Dusseau, Professor, Computer Science

    Signature of Professor: #underline(" " * 60) Date: #underline(" " * 25)
  ]



  pagebreak(weak: true)
}

#let preview = false

#let thesis-body(content) = {
  set heading(numbering: "1.1")
  show ref: it => {
    if preview {
      if query(it.target) != () {
        it
      } else {
        it.target
      }
    } else {
      it
    }
  }

  show figure.where(kind: "algorithm"): set align(left)
  show figure.where(kind: "algorithm"): it => showybox(
    frame: (
      border-color: green.darken(50%),
      title-color: green.lighten(60%),
      body-color: green.lighten(90%),
      body-inset: 1em,
    ),
    title-style: (
      color: black,
      weight: "regular",
      align: center,
    ),
    shadow: (
      offset: 2pt,
    ),
    title: it.caption,
    it.body,
  )

  show: codly-init.with()

  codly(languages: (
    rust: (name: "Rust", icon: "🦀", color: rgb("#CE412B")),
  ))


  set text(size: 12pt)

  show heading.where(level: 1): set text(font: "Source Sans 3", size: 25pt, weight: "medium")
  show heading.where(level: 2): set text(size: 18pt)

  set page(
    margin: (top: 2in, bottom: 2in, left: 1.5in, right: 1.5in),
    header: [
      #h(1fr) #context {
        let page_numbering = here().page-numbering()
        if page_numbering != none {
          counter(page).display(page_numbering)
        }
      }
    ],
  )

  show heading.where(level: 1): it => block(
    below: 2em,
    {
      v(4em)
      h(1fr)
      it.body
    },
  )

  show heading.where(level: 2): set block(above: 3em, below: 1em)
  show heading.where(level: 3): set block(above: 2em, below: 1em)
  show heading.where(level: 4): set block(above: 2em, below: 1em)
  show heading.where(level: 5): set block(above: 2em, below: 1em)


  set par(leading: 1em, first-line-indent: 1em, justify: true)

  show outline: set par(leading: 1.5em)

  content

  include "reference.typ"
}

#let algorithm = figure.with(kind: "algorithm", supplement: "Algorithm")
