#import "/template/_helpers.typ": title-caption
#import "@preview/acrostiche:0.5.0": acr, acrfull

= Introduction


//. #cite(<AttentionIsAllYouNeed>, form: "prose") also said, that this is an inline citation.

// You can also link to headings @H:used_tools or @H:method, to tables @T:table and so on.

// Footnotes are pretty easy as well#footnote[https://www.grammarly.com/].

// You can use acronyms like #acr("CSV") or #acrfull("CSV") for the full name. This then shows up in the list of abbreviations.


== Background and motivation 

The foundation of science rests upon the integrity and reliability of its published literature, serving as a cumulative process where new discoveries build upon existing knowledge. However, this crucial foundation is increasingly threatened by the rise of fraudulent scientific publications. A significant driver of this problem is the intense pressure on researchers, academics, and students to publish their work in peer-reviewed journals for career advancement, such as tenure, promotion, and pay. This "publish or perish" culture creates an environment where some individuals may resort to questionable research practices or outright fraud to meet performance expectations @acharyaPublicationPressureScientific2025.

 
The fraudulent landscape includes various forms of misconduct, such as the publication of nonsensical algorithmically generated papers, data fabrication and manipulation, image manipulation, citation manipulation, peer review manipulation, and the use of paper mills. Paper mills are organizations that produce and sell fraudulent academic manuscripts, often offering authorship for a fee. These entities exploit the pressure on researchers to publish, compromising the integrity of scientific literature. The operations of paper mills include fabricating data, manipulating images, and submitting manuscripts with fake authorship, making detection challenging for publishers. Studies have shown a significant number of retracted papers can be traced back to such practices, highlighting the need for vigilant editorial processes. Such articles, even when accepted by reputable publishers, can be highly unreliable and damaging. 

A sharp rise in such unreliable publications has been observed in recent years. For instance, Retraction Watch reported a record number of nearly 5,000 retractions in 2022 alone (see @retractionwatch-2022), highlighting the alarming scale of this problem in contemporary academic publishing @oranskyNearing5000Retractions2022.



#figure(
  image("/images/retraction watch.png", width: 70%),
  caption: title-caption(
    [Number of retractions recorded per year],
    [Number of retractions recorded per year as reported by Retraction Watch (2022)],
  )
)<retractionwatch-2022>


The emergence of advanced Artificial Intelligence (AI) writing capabilities and Large Language Models (LLMs), which are deep learning models trained on massive corpora to generate human-like text, further exacerbates the challenge, enabling the quick fabrication of deceptive 'original' research that can evade detection by standard checks @majovskyArtificialIntelligenceCan2023.

This rise in fraudulent content has tangible and severe consequences. It undermines the credibility of academic publications and erodes public trust in science. Flawed or falsified findings, if undetected, can remain in the literature, misleading future research and wasting valuable time and resources. Such misconduct poses a major and ongoing challenge for the entire scholarly publishing industry and everyone who relies on the integrity of the scholarly record. Addressing this challenge requires proactive monitoring and analysis.

== Importance of research integrity
Research integrity is paramount because the quality and credibility of future scientific results directly depend on the soundness of past published research. Scientific progress depends on a reliable body of existing knowledge. When fraud occurs, it is highly damaging to the reputation of the entire scientific community, hinders scientific progress, and can have unpredictable consequences, especially in life-critical fields like medicine and public health. Maintaining research integrity is therefore essential for preserving the reliability of the scientific record and fostering public trust.

== Objective of the thesis
Given the increasing threat posed by various forms of fraud and manipulation in scientific publications, the objective of this thesis is to investigate and evaluate automated methods for their detection. By analyzing the characteristics of fraudulent content, this research aims to contribute to the development or assessment of tools that can help identify suspicious publications and uphold research integrity.

== Research questions

This thesis aims to answer the following research questions:
- What are the key characteristics and patterns observed in different types of fraudulent scientific publications, such as algorithmically generated text, paper mill products, and data manipulation?
- How effectively can automated text-based methods, such as NLP techniques and machine learning classifiers, detect fraudulent content based on linguistic features and structural anomalies?
- Can network-based analysis of scholarly data, such as citation patterns, reveal indicators of fraudulent activity?
- How do different automated detection approaches compare in terms of performance, applicability, and scalability for identifying various forms of fraud in scientific literature?




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
