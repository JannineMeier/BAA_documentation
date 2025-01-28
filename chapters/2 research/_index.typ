#import "@preview/acrostiche:0.5.0": acr, acrfull
#import "/template/_helpers.typ": title-caption

= State of the Art in Research

As you can see, figure numbers are automatically generated according to the chapter they are in:
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
)<T:table2>
