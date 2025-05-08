#import "@preview/acrostiche:0.5.0": acr, acrfull
#import "/template/_helpers.typ": title-caption

= Related Work

Fraud detection in scientific literature The challenge of detecting fraud in scientific literature has spurred research into various automated and semi-automated approaches. Manual checks are often insufficient due to the sheer volume of publications (more than 1.4 million papers a year) and the increasing sophistication of fraudulent practices. Fraudulent data, by its nature, is often designed to elude the self-correcting processes of science. Therefore, any process that can uncover potentially fabricated or fraudulent content is welcomed by the academic community.

Detection efforts target various forms of misconduct. One focus is on identifying nonsensical algorithmically generated papers, particularly those created using probabilistic context-free grammars like SCIgen and Mathgen. These papers contain fixed word sequences or "fingerprints" derived from the grammar rules, which are unlikely to appear in genuine papers. Another growing area is the detection of AI-generated text (AIGT), as LLMs can produce human-like content that is difficult to distinguish from genuine writing. The emergence of "paper mills" necessitates methods to identify documents resulting from these organizations, often characterized by similarities to known paper mill products. Data-related fraud, such as fabricated or manipulated datasets, is another critical target. This can be particularly difficult to detect without access to raw data. Image manipulation, including the use of invented or slightly modified stock images, is also a known paper mill tactic requiring specific detection methods. Finally, manipulation can extend to meta-data and publication processes, including peer review fraud involving fake accounts or duplicated comments, and citation manipulation or "citation rings".

Automated detection methods are crucial for screening manuscripts before peer review and chasing manipulation in published papers. These tools are intended to complement human curators and editors in the screening process, not necessarily to automate rejection decisions. The ideal scenario involves a multi-stakeholder effort, including authors, co-authors, journals, and institutions, to enhance research integrity.

NLP applications for academic text classification Natural Language Processing (NLP) plays a significant role in developing text-based methods for fraud detection. These methods analyze the linguistic and structural properties of scientific texts to identify anomalies indicative of fraudulent origin.
One approach involves analyzing stylometric features, which are related to authorship attribution and profiling tasks. Retracted papers have been shown to exhibit distinct phrase patterns and higher word repetition compared to non-retracted papers.

Another successful technique is the identification of fixed word sequences or "fingerprints" characteristic of specific text generators, such as SCIgen. This method, exemplified by the "search and prune" approach, uses academic search engines capable of searching full-text to find candidate papers containing these fingerprints. A pruning step is then used to eliminate false positives. This method has been shown to be effective in identifying unmodified SCIgen-generated papers and some papers with SCIgen padding.

With the rise of advanced language models, NLP research has focused on using Transformer-based models for text classification tasks, including detecting AIGT and paper mill content. Models like BERT, RoBERTa, DeBERTa-v3, SciBERT, and SciDeBERTa have been fine-tuned for this purpose, achieving high accuracy in detecting paper mill articles and automatically generated content by analyzing linguistic differences. These models leverage the ability of Transformers to capture complex language patterns and structures. Other text-based indicators include the detection of awkwardly phrased text or unusual alternatives to standard terminology, which might result from automatic translation used by paper mills. Detecting text duplication or plagiarism is also a crucial NLP task in identifying misconduct.
Network-based analysis in scholarly data Analyzing the relationships and structures within scholarly data provides another avenue for fraud detection, often through network analysis.

One application is the study of author collaboration networks. Research comparing the networks of authors with retracted papers to those with non-retracted papers has revealed structural differences. Retracted collaboration networks tend to exhibit more hierarchical and centralized structures, with strong correlations between degree and centrality measures. In contrast, non-retracted networks emphasize more distributed collaboration with strong clustering and connectivity, indicating more balanced structures. Metrics such as Degree Centrality, Average Weighted Degree, and Closeness Centrality have been identified as revealing statistically significant structural differences between these networks. Understanding how retraction-prone collaborations form can inform policies to improve research practices.

Peer review manipulation can also be investigated through network analysis, examining the connections between authors and reviewers. Detection methods analyze peer review comments for duplication or overlap, and can identify accounts of fake authors and reviewers.
While not explicitly detailed in the sources in terms of network analysis methods, the detection of citation manipulation inherently involves analyzing citation networks to identify suspicious patterns like citation rings.

Overview of existing tools, datasets, and approaches A range of tools and approaches have been developed or proposed to combat scientific fraud.
Tools and Software:
- SCIDetect: Software designed to classify papers as generated or not, integrated into editorial workflows.
- Grammar-based detectors: Methods that identify computer-generated papers based on probabilistic context-free grammars. This includes the "search and prune" method which uses fingerprint-queries against full-text search engines.
- PaperMill Detection framework: A modular system leveraging contextual signals, including a PaperMill Document Detector (PMDD) identifying similarities to known paper mill documents and an AI-Generated Text Detector (AIGTD) for detecting LLM-generated content. This framework uses AI-powered modules and NLP.
- Transformer-based classifiers: Models fine-tuned on pre-trained Transformers to classify papers or text segments based on linguistic patterns indicative of paper mills, randomly generated content, or falsification.
- Distributional Quantification Framework (DQF): A statistical method based on linguistic structure to estimate the rate of misconduct.
- Benford's Law analysis: An analytical process utilizing Benford's Law to screen for data anomalies and potentially identify fabricated or manipulated data.
- Plagiarism detectors: Software to identify text duplication.
- Some publishers, like Hindawi, have developed bespoke software applications for large-scale investigation and assessment of problematic papers, combining automated checks with human review. Journals are also integrating detection software into their screening processes.

=== Datasets
Detection methods rely on various data sources for training and evaluation:
- Academic Search Engines: Platforms like Google Scholar and Dimensions are valuable as they index papers in full-text, enabling methods based on searching for specific patterns. Google Scholar has wider coverage but lacks programmatic access, while Dimensions offers API access.
- Retraction Databases: The Retraction Watch database is a key source for identifying retracted papers and their stated reasons for retraction.
- Bibliographic Databases: Scopus, OpenAlex, and Microsoft Academic Graph (MAG) provide metadata, abstracts, and sometimes full text of scholarly documents. OpenAlex, for instance, includes information on authors, affiliations, and topics.


=== Approaches
Fraud detection in scientific publications encompasses multiple approaches:
- Text-based methods: Analyzing linguistic features, writing style, specific keywords, and patterns using NLP and machine learning.
- Data-based methods: Examining numerical data within papers for statistical anomalies, such as deviations from Benford's Law.
- Image-based methods: Detecting manipulation, duplication, or reuse of images.
- Network-based methods: Analyzing relationships between authors, reviewers, papers, or citations to identify suspicious structures or patterns.
- Metadata-based methods: Using information about authors, affiliations, email domains, or publication venues to flag suspicious submissions.

It is widely suggested that no single automated solution is sufficient on its own; these tools should be used as screening processes to highlight potential "red flags" that trigger deeper human investigation and discussion with the authors. This process will not prevent fraudulent behaviour entirely but aims to make it riskier and more difficult for fraudsters.

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
