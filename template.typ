#import "utils.typ": *
#import "@preview/codly:1.1.1": *
#import "@preview/codly-languages:0.1.3": *

#let front-page(title, authors, college, degree-program, date) = {
  set text(font: "Times New Roman", size: 12pt)
  set page(margin: 1in)
  v(4em)
  align(center, {
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
  })
  
  v(1fr)

  [
    This thesis was completed under the direction of:\
    #h(2em) Remzi Arpaci-Dusseau, Professor, Computer Science

    Signature of Professor: #underline(" " * 60) Date: #underline(" " * 25)
  ]

  

  pagebreak(weak: true)
}


#let thesis-body(content) = {
    show: codly-init.with()

    set text(size: 12pt)

    show heading.where(level: 1): set text(font: "Source Sans 3", size: 25pt, weight: "medium")
    show heading.where(level: 2): set text(size: 18pt)

    set page(margin: (top: 2in, bottom: 2in, left: 1.5in, right: 1.5in), header: [
        #h(1fr) #context {
            let page_numbering = here().page-numbering()
            if page_numbering != none {
                counter(page).display(page_numbering)
            }
        }
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

    set par(leading: 1em, first-line-indent: 1em, justify: true)
    
    show outline: set par(leading: 1.5em)


    content

    include "reference.typ"
}