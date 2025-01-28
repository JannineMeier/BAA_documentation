#import "@preview/codly:1.1.1": *
#import "@preview/codly-languages:0.1.3": *

// Init codly. If live preview stops working, remove this block until the final generation of the report
// #show: codly-init.with()
// #codly(languages: codly-languages)
//
// Import the glossary
#include "_glossary.typ"

#import "/template/template.typ": template

#let report_date = datetime(year: 2025, month: 1, day: 1)
// If you want to have different dates for report, graduation and/or signature, change them here
#let signature_date = report_date
// Only the year is displayed for the graduation date
#let graduation_date = report_date

#let expression_content = [
  I would like to thank my family, friends, and colleagues for their support and encouragement throughout the course of my studies. I would also like to express my gratitude to my advisor, Prof. Dr. Advisor, for his guidance and feedback on this thesis. Finally, I would like to thank Dr. External Expert for his valuable input and feedback on this work.
]

#let abstract_content = [
  This is the abstract of the thesis. It should be a brief summary of the content of the thesis, including the research question, methodology, results, and conclusions. The abstract should be concise and informative, providing the reader with an overview of the key points of the thesis.
]

#show: template.with(
  title: "This is a title of a thesis",
  subtitle: "This is a subtitle of a thesis",
  // You MUST keep a trailing comma here, even if there is only one author
  authors: (
    (
      name: "Lastname Firstname",
      address: "Suurstoffi 1, 6343 Risch-Rotkreuz",
      email: "firstname.lastname@stud.hslu.ch",
    ),
  ),
  university: "Lucerne University of Applied Sciences and Arts",
  division: "School of Computer Science and Information Technology",
  report_date: report_date,
  advisor: "Prof. Dr. Advisor",
  external_expert: "Dr. External Expert",
  industry_partner: [Industry AG\ Some Person\ Somestreet 69\ 4269 Nice],
  degree_program: "BSc AI & ML",
  degree_program_full: "Bachelor of Science in Artificial Intelligence & Machine Learning",
  graduation_date: graduation_date,
  confidential: true,
  signature_date: signature_date,
  signature_place: "Risch-Rotkreuz",
  expression_content: expression_content,
  abstract_content: abstract_content,
  bibliography_link: "/BAA.bib",
  appendix_index: "/chapters/8 appendix/_index.typ",
)

#include "chapters/_index.typ"
