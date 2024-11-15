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
