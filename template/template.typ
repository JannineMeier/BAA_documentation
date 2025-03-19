#import "@preview/acrostiche:0.5.0": print-index, reset-all-acronyms
#import "_cover.typ": cover
#import "_declaration.typ": declaration
#import "_expression.typ": expression
#import "_abstract.typ": abstract

#let template(
  title: none,
  subtitle: none,
  authors: none,
  university: none,
  program: none,
  report_date: none,
  advisor: none,
  external_expert: none,
  industry_partner: none,
  degree_program: none,
  degree_program_full: none,
  graduation_date: none,
  confidential: none,
  signature_date: none,
  signature_place: none,
  expression_content: none,
  division: none,
  abstract_content: none,
  bibliography_link: none,
  appendix_index: none,
  doc,
) = {
  // Set document metadata
  set document(title: title, author: authors.map(author => author.name))

  // Set the page size to A4
  set page(paper: "a4", numbering: "1")

  // Set font, size and language for the whole document
  set text(
    font: "Times New Roman",
    size: 12pt,
    lang: "en",
  )

  // All paragraphs are justified
  set par(justify: true)

  // All links are underlined
  show link: underline

  // Set heading styles
  show heading: it => {
    if (it.level == 1) {
      pagebreak(weak: true)

      counter(math.equation).update(0)
      counter(figure.where(kind: table)).update(0)
      counter(figure.where(kind: math.equation)).update(0)
      counter(figure.where(kind: image)).update(0)

      if (it.supplement != []) {
        v(50pt, weak: true)
        text(size: 18pt, it.supplement + " " + counter(heading).display())
        v(20pt, weak: true)
      }

      v(20pt, weak: true)
      text(size: 25pt, it.body)
      v(30pt, weak: true)
    } else {
      if (it.level == 2) {
        v(30pt, weak: true)
        text(size: 15pt, it)
        v(20pt, weak: true)
      } else if (it.level == 3) {
        v(20pt, weak: true)
        text(size: 12pt, it)
        v(10pt, weak: true)
      } else {
        v(20pt, weak: true)

        if (it.level == 4) {
          counter(heading).display() + ""
        }

        text(size: 1em, it.body)
        v(10pt, weak: true)
      }
    }
  }

  // Equations are numbered by chapter and are reset at the start of each chapter
  set math.equation(numbering: n => numbering("(1.1)", counter(heading).get().first(), n))

  // Figures are numbered by chapter and are reset at the start of each chapter
  set figure(numbering: n => numbering("1.1", counter(heading).get().first(), n))

  let listIndent = 1em
  // All lists use a hyphen as marker, are indented by listIndent and have a margin of listMargin
  set list(
    marker: ([-], [•]),
    indent: listIndent,
  )
  // All enums can use multiple depths, are indented by listIndent and have a margin of listMargin
  set enum(
    full: true,
    indent: listIndent,
  )

  //Add some spacing after a figure
  show figure: it => {
    it
    v(1em)
  }

  import "_helpers.typ": show-title
  // In outlines, show the short title of figures
  show outline: it => {
    show-title.update(true)
    it
    show-title.update(false)
  }

  // In figures, display the caption title and body in a 2 column grid
  show figure.caption: c => {
    if (c.kind != math.equation) {
      grid(
        columns: 2,
        column-gutter: 4pt,
        align(top)[
          #c.supplement #context(c.counter.display(c.numbering)).#c.separator],
        align(left, c.body),
      )
    }
  }

  [
    #set page(numbering: none)
    #set heading(supplement: none, outlined: false)
    #show: cover(
      title: title,
      subtitle: subtitle,
      authors: authors,
      university: university,
      degree_program_full: degree_program_full,
      report_date: report_date,
    )
    #pagebreak()
  ]

  [
    #set page(numbering: none)
    #set heading(supplement: none, outlined: false)
    #show: declaration(
      title: title,
      authors: authors,
      advisor: advisor,
      external_expert: external_expert,
      industry_partner: industry_partner,
      degree_program: degree_program,
      graduation_date: graduation_date,
      confidential: confidential,
      signature_date: signature_date,
      signature_place: signature_place,
      university: university,
      division: division,
    )
  ]

  [
    #set page(numbering: none)
    #set heading(supplement: none, outlined: false)
    #show: expression(expression_content: expression_content)
  ]


  // Set page numbering to roman for abstract
  // Also disable heading supplements for these sections
  [
    #set page(numbering: "I")
    #counter(page).update(1)

    #set heading(supplement: none, outlined: false)

    #show: abstract(abstract_content: abstract_content)
  ]

  // Set page numbering to roman for content table
  // Also disable heading supplements for these sections
  [
    #set page(numbering: "I")
    #counter(page).update(2)

    #set heading(supplement: none, outlined: false)

    // For the content table, don't show dot's between the
    // heading and the page number for the first level and
    // make the text bold. Hide headings smaller than level 4.
    #show outline.entry: it => {
      if it.level == 1 {
        v(16pt, weak: true)

        strong(it.body())
        box(width: 1fr, repeat(" "))
        strong(it.page())
      } else if it.level < 4 and it.element.has("supplement") {
        it
      }
    }

    #outline(indent: auto)
  ]

  // After the oultine, reset all acronyms
  reset-all-acronyms()

  // Reset the page and heading counter
  counter(page).update(1)
  counter(heading).update(0)
  set heading(numbering: "1.1   ", supplement: "Chapter")

  doc

  // Set the heading numbering to roman for the appendices and reset the heading counter
  set heading(numbering: "A.1   ", supplement: "Chapter")
  counter(heading).update(0)

  set figure(outlined: false, numbering: "A.1")

  reset-all-acronyms()
  print-index(
    title: "List of Abbreviations",
    numbering: "A.1 ",
    outlined: true,
    used-only: true,
    sorted: "up",
    row-gutter: 8pt,
  )

  // Give all outlines a heading number
  show outline: set heading(
    numbering: "A.1 ",
    outlined: true,
  )

  outline(
    title: "List of Figures",
    target: figure.where(kind: image),
  )

  outline(
    title: "List of Tables",
    target: figure.where(kind: table),
  )

  outline(
    title: "List of Equations",
    target: figure.where(kind: math.equation),
  )

  // Give the bibliography heading a number as well
  show bibliography: set heading(numbering: "A.1 ")

  bibliography(
    bibliography_link,
    style: "american-psychological-association",
  )

  // Appendix
  // Disable outlined headings for the appendix
  set heading(outlined: false)

  include appendix_index
}
