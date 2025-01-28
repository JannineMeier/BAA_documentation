#align(top + right)[
  #image("./images/HSLU_2022_log.png", width: 30%)
]

#let cover(
  title: none,
  subtitle: none,
  authors: (),
  university: none,
  degree_program_full: none,
  report_date: none,
) = {
  align(horizon + center)[

    #text(size: 24pt, [#title])\

    #v(0.5em)

    #subtitle

    #v(2em)


    #let count = authors.len()
    #let ncols = calc.min(count, 3)

    #let author_title = "Author"
    #if (count > 1) {
      author_title = author_title + "s"
    }

    *#author_title*
    #grid(
      columns: (1fr,) * ncols,
      row-gutter: 24pt,
      ..authors.map(author => [
        #author.name \
        #author.address \
        #link("mailto:" + author.email)
      ]),
    )

    #v(3em)

    #university\
    #degree_program_full

    #v(2em)

    #report_date.display("[month repr:long] [day], [year]")
  ]
}
