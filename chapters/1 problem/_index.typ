#import "/template/_helpers.typ": title-caption
#import "@preview/acrostiche:0.5.0": acr, acrfull

= Introduction

This is a citation @AttentionIsAllYouNeed. #cite(<AttentionIsAllYouNeed>, form: "prose") also said, that this is an inline citation.

You can also link to headings @H:used_tools or @H:method, to tables @T:table and so on.

Footnotes are pretty easy as well#footnote[https://www.grammarly.com/].

You can use acronyms like #acr("CSV") or #acrfull("CSV") for the full name. This then shows up in the list of abbreviations.

== Background and motivation

#lorem(20)

== Importance of research integrity

#lorem(20)

== Objective of the thesis

#lorem(20)

== Research questions



#figure(
  image("/images/signature.png"),
  caption: title-caption(
    [This is a image caption title],
    [This is a realllllllllllllllllllllllllllllllllllllllly long image caption body. This is not shown in the list of figures.],
  ),
)

#figure(
  table(
    columns: 2,
    table.header(
      [Header 1],
      [Header 2],
    ),

    [Row 1, Column 1], [Row 1, Column 2],
  ),
  caption: title-caption(
    [This is a table caption title],
    [This is a realllllllllllllllllllllllllllllllllllllllly long table caption body. This is not shown in the list of figures.],
  ),
)<T:table>

#figure(
  kind: math.equation,
  $ R^2 = 1 - frac(\SS_(R E S), \SS_(T O T)) = 1 - frac(sum_i (y-hat(y)_i)^2,sum_i (y-macron(y)_i)^2) $,
  caption: "This is an equation title",
)
