
#let declaration(
  title: none,
  authors: (),
  advisor: none,
  external_expert: none,
  industry_partner: none,
  degree_program: none,
  graduation_date: none,
  confidential: none,
  signature_date: none,
  signature_place: none,
  university: none,
  division: none,
) = {
  [== Bachelor Thesis at #university #division]

  let name_of_student = "Name of Student"
  if (authors.len() > 0) {
    name_of_student = name_of_student + "s"
  }

  table(
    columns: 2,
    stroke: none,
    row-gutter: 1em,
    column-gutter: 2em,
    [*Title of Bachelor Thesis:*], [#title],
    [*#name_of_student:*], [#authors.map(a => a.name).join(" \ ")],
    [*Degree Program:*], [#degree_program],
    [*Year of Graduation:*], [#graduation_date.display("[year]")],
    [*Main Advisor:*], [#advisor],
    [*External Expert:*], [#external_expert],
    // [*Industry partner/provider:*], [#industry_partner],
  )

  [
    *Code / Thesis Classification:*\
    #if (confidential) {
      [
        ⬜ Public (Standard)\
        ☑ Confidential (Restricted)
      ]
    } else {
      [
        ☑ Public (Standard)\
        ⬜ Confidential (Restricted)
      ]
    }

    *Declaration*\
    I hereby declare that I have completed this thesis alone and without any unauthorized or external help. I further declare that all the sources, references, literature and any other associated resources have been correctly and appropriately cited and referenced. The confidentiality of the Lucerne University of Applied Sciences and Arts have been fully and entirely respected in completion of this thesis.

    #stack(
      grid(align: bottom + center, columns: (1fr, 1fr))[
        #signature_place, #signature_date.display("[day].[month].[year]")
      ][
        #image(
          "/images/signature.png",
          height: 3em,
        )
      ],
      spacing: .5em,
      line(length: 100%, stroke: (thickness: .5pt)),
      "Place / Date, Signature",
    )

    *Submission of the Thesis to the Portfolio Database:*\
    Confirmation by the student\
    I hereby confirm that this bachelor thesis has been correctly uploaded to the Portfolio Database in line with the code of practice of the University. I rescind all responsibility and authorization after upload so that no changes or amendments to the document may be undertaken.

    #stack(
      grid(align: bottom + center, columns: (1fr, 1fr))[
        #signature_place, #signature_date.display("[day].[month].[year]")
      ][
        #image(
          "/images/signature.png",
          height: 3em,
        )
      ],
      spacing: .5em,
      line(length: 100%, stroke: (thickness: .5pt)),
      "Place / Date, Signature",
    )
  ]
}
