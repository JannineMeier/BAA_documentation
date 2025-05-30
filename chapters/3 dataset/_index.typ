#import "/template/_helpers.typ": todo
#import "/template/_helpers.typ": title-caption
#import "@preview/acrostiche:0.5.0": acr, acrfull

= Data Sources 

== Dataset Construction

This thesis builds upon the dataset introduced by Analyzing the Evolution of Scientific Misconduct based on the Language of Retracted Papers @blessetal.AnalyzingEvolutionScientific2025, which combines two main data sources:

- Retraction Watch: A comprehensive database of retracted scientific articles, annotated with detailed retraction reasons.

- OpenAlex: A large-scale open-access scholarly graph providing metadata such as abstracts, citations, authors, institutions, and subject classifications.

The dataset merges these sources to enable systematic analysis of scientific misconduct, especially in linguistic and structural terms. I reused this dataset as a foundation and expanded it through additional preprocessing, filtering, and metadata enrichment.

The original dataset was constructed by merging Retraction Watch entries with corresponding OpenAlex metadata, resulting in \~30k unique retracted articles, of which \~19k had usable abstracts. Content-rich sections such as Introduction, Methods, and Conclusion were already extracted in the original dataset. These were identified using regular expression-based heuristics applied to the full text and labeled accordingly. I reused these pre-labeled sections without modifying the paragraph segmentation, and focused primarily on the Abstract for my core experiments  due to  consistent availability and conciseness.


=== Filtering and Balancing

To prepare a balanced dataset suitable for binary classification:

- Retracted Papers: I filtered the retraction corpus to include only papers with a non-empty abstract, as abstracts served as the primary textual input across most experiments. 

- Non-Retracted Papers: I adopted the control sample defined by @blessetal.AnalyzingEvolutionScientific2025, consisting of highly cited, non-retracted articles matched by year and research field. These were originally chosen under the assumption that well-cited papers are less likely to be retracted and provide a stable reference set. I randomly downsampled this set to match the size of the retracted group.



=== Labeling Strategy

The Retraction Watch database contains over 100 retraction reason categories, and a single paper may be associated with multiple overlapping reasons (see @labeloverlap).

For the purpose of binary classification, I defined scientific fraud as retraction reasons that clearly suggest intentional deception or systematic misconduct (e.g., “Fake Peer Review”, “Fabricated Data”). Ambiguous, procedural, or non-deceptive issues such as authorship disputes, plagiarism, or publisher error were excluded from the fraud definition.

Papers were assigned the positive class (scientific fraud) if they matched at least one fraud-related retraction reason from my defined subset. All non-retracted papers formed the negative class (non-retracted). This approach allowed for a focused classification task centered on fraud detection.


=== Metadata Retention
The dataset retains a curated set of metadata fields relevant for modeling and analysis:

- Field, Domain, Country: Represent the research area and geographic context.

- Author, Institution: Capture collaboration metadata as semicolon-separated lists.

- OriginalPaperDate: Used to extract publication year for temporal analysis.

- retracted: The binary target label (fraud vs. non-retracted).

The Language column was excluded, as over 99% of papers were written in English. The few non-English entries (e.g., in German or French) were too sparse to contribute meaningfully to classification and could introduce unnecessary noise.

Further details on how these metadata features were transformed and engineered can be found in @feature_eng.

=== Similarity Score Features

To assess the semantic alignment between citing papers and their references, I incorporated four similarity-based features developed by Christof Bless. These features, detailed in the GitHub repository (https://github.com/Christof93/citation_semantic_congruence), quantify the semantic distance between citation contexts and cited abstracts using L2 (Euclidean) distance on sentence embeddings.

The sentence embeddings were generated using the SPECTER model, a transformer-based encoder trained on scientific literature.

The features are:

- *mean_citation_context_to_cited_abstract_l2_distance_y*: Average distance between each citation context in the citing paper and the abstract of the cited paper, indicating overall semantic similarity.

- *max_citation_context_to_cited_abstract_l2_distance_y*: Maximum distance observed among all citation context–cited abstract pairs, highlighting potential outlier citations.

- *mean_abstract_to_cited_abstract_l2_distance_y*: Average distance between the citing paper's abstract and the abstracts of all cited papers, reflecting general alignment.

- *max_abstract_to_cited_abstract_l2_distance_y*: Maximum distance between the citing abstract and any cited abstract, identifying significant semantic deviations.

Due to limitations in available metadata, these features could be computed for approximately 8,000 papers, comprising 6,000 retracted and 2,000 non-retracted articles. The remaining ~12,000 papers lacked sufficient data for these calculations. Despite this, the similarity features offer valuable insights into the degree of content overlap and potential anomalies in citation practices.


=== Retraction Reason Selection and Labeling <labeling>

The Retraction Watch database contains over 100 retraction reasons, and each paper can be associated with multiple labels. To enable a clear and well-defined binary classification task (fraudulent vs. non-retracted), I manually selected a subset of retraction reasons that explicitly indicate scientific fraud.

The reasons were grouped into two high-level categories:

- Manipulation of the Publication Process

    - Fake Peer Review 

  - Paper Mill 

  - Rogue Editor

- Scientific Misconduct by Authors

  - Misconduct by Author 

  - Falsification/Fabrication of Results 

  - Falsification/Fabrication of Data 

  - Randomly Generated Content 

A third category, High-Risk Author, was created to flag papers under investigation:

- Investigations by journals, institutions, or third parties

- Author unresponsiveness or complaints



Due to significant overlap between these categories as seen in @labeloverlap, I merged them into a single binary label: 

- 1 → Retracted due to fraud or misconduct

- 0 → Not retracted

This binary definition enabled focused modeling on misconduct cases while excluding procedural retractions or honest errors (e.g., plagiarism, authorship disputes, data loss).


#figure(
  image("/images/venn_labels.png", width: 50%),
  caption: title-caption(
    [Overlap Between Retraction Reason Categories],
    [Overlap Between Retraction Reason Categories in the Retraction Watch Database],
  )
)<labeloverlap>

= Preprocessing

== Feature Extraction and Engineering<feature_eng>

To support diverse modeling strategies, I engineered features across three modalities:

1. Metadata features — numerical and categorical data (e.g., year, country, author count)

2. Text-based features — semantic representations (e.g., TF-IDF, sentence embeddings)

3. Citation-based features — graph-derived metrics (e.g., in/out degree, node embeddings)

=== Metadata Feature Engineering
Metadata fields such as Author, Institution, and Country were originally stored as semicolon-separated strings. To make these usable for machine learning, I performed two main transformations:

- Count-based indicators:
  - num_authors: Number of authors

  - num_institutions: Number of listed institutions

  - num_countries: Number of countries based on affiliations

- Top-N indicators: For frequently occurring authors (top 100), institutions (top 50), and countries (top 20), I created binary features indicating their presence. All other entries were grouped under "Other" as described in @onehot.

These transformations not only reduced noise but also improved generalizability by focusing the model on frequent and robust patterns. Avoiding rare or overly specific entries (e.g., institutions listed in only 1–2 papers) helped prevent overfitting and made the model more adaptable to unseen data.

A full overview of all derived metadata features, including their names, types, and descriptions, is provided in Appendix.

=== Text-Based Features

Two core representations were extracted from the Abstract and full text:

- TF-IDF Vectors: Sparse bag-of-words representations reflecting term frequency patterns

- Sentence Embeddings: Dense vector representations using microsoft/deberta-v3-small via the sentence-transformers library

=== Handcrafted Text Features

I engineered a diverse set of handcrafted features to capture different characteristics of the text in a more interpretable way. These features were designed to reflect writing style, structure, and linguistic patterns that could help distinguish between retracted and non-retracted papers.

The features were extracted from two main text sources:
- *the abstract*
- *the full text*, which I generated by concatenating the labeled content sections (Abstract, Introduction, Related Work, Methods, Result & Discussion, and Conclusion) from the dataset.

To process the texts, I used tokenization from the NLTK library and regular expressions for pattern matching. I also removed stopwords using NLTK's built-in stopwords.words('english') list.

I developed 60 interpretable text features. 30 based on the abstract (hc_) and 30 from the full text (hc_ft_). These include:
- Basic Statistics: char_count, word_count, sentence_count, etc.
- Linguistic Ratios: stopword_ratio, type_token_ratio, digit_ratio
- Stylistic Patterns: modal_verb_count, negation_count, pronoun_we_count
- Punctuation & Structure: quote_count, question_count, comma_count
- Lexical Complexity: long_word_ratio, avg_token_length

All features were standardized with StandardScaler and stored in the final dataset.

A full list of features is provided in Appendix @T:featuredescription.

#figure(
  table(
    columns: 2,
    table.header(
      [Feature Name],
      [Description],
    ),

    [hc_00_char_count], [Total number of characters in the text],
    [hc_01_word_count], [Total number of words in the text],
    [hc_02_avg_word_len], [Average word length in the text],
    [hc_03_stopword_count], [Number of stopwords in the text],
    [hc_04_stopword_ratio], [Ratio of stopwords to total words],
    [hc_05_sentence_count], [Number of sentences in the text],
    [hc_06_avg_sentence_length], [Average number of words per sentence],
    [hc_07_type_token_ratio], [Type-token ratio (vocabulary richness)],
    [hc_08_uppercase_ratio], [Ratio of uppercase characters],
    [hc_09_digit_ratio], [Ratio of digits to total characters],
    [hc_10_special_char_ratio], [Ratio of special characters],
    [hc_11_passive_like], [Count of passive-like verb phrases],
    [hc_12_negation_count], [Number of negation words],
    [hc_13_modal_verb_count], [Number of modal verbs],
    [hc_14_pronoun_we_count], [Occurrences of 'we'],
    [hc_15_pronoun_i_count], [Occurrences of 'I'],
    [hc_16_certainty_word_count], [Count of certainty words (e.g., 'always')],
    [hc_17_hedge_word_count], [Count of hedge words (e.g., 'might', 'seems')],
    [hc_18_lexical_density], [Ratio of content words to total words],
    [hc_19_question_count], [Number of question marks],
    [hc_20_exclamation_count], [Number of exclamation marks],
    [hc_21_quote_count], [Number of quotation marks],
    [hc_22_comma_count], [Number of commas],
    [hc_23_colon_count], [Number of colons],
    [hc_24_semicolon_count], [Number of semicolons],
    [hc_25_adj_count], [Number of adverbs (words ending in -ly)],
    [hc_26_avg_token_length], [Average token length],
    [hc_27_long_word_ratio], [Ratio of words with more than 6 characters],
    [hc_28_short_word_ratio], [Ratio of words with 3 or fewer characters],
    [hc_29_period_count], [Number of periods in the text],
  ),
  caption: title-caption(
    [Overview of 30 Handcrafted Linguistic Features],
    [Each feature was computed for both abstract (`hc_`) and full text (`hc_ft_`) versions to quantify structure, syntax, and style for each paper.],
  ),
)<T:featuredescription>

== Additional Metadata Enrichment via OpenAlex API
To extend the dataset with citation-related structural information, I implemented a custom asynchronous crawler using the OpenAlex API. This enrichment phase provided essential graph-based features for downstream analysis.

Each paper was identified by its DOI and augmented with:
- Outgoing citations: A list of DOIs representing all works referenced by the article.
- Incoming citations: A list of OpenAlex records (IDs, DOIs, titles) for all articles that cite the target paper. These were retrieved via paginated queries and merged for full coverage.

Not all papers had complete citation metadata available via OpenAlex. Some entries were missing DOI mappings or had incomplete incoming citation data. These were excluded from graph-based features to maintain consistency.

To ensure robust and efficient querying, I registered a personal API key, which allowed for higher rate limits and greater stability during large-scale requests.


=== Citation Graph Construction
Using the enriched citation data, I constructed a directed graph with networkx.DiGraph, where:

- Nodes represent papers (by DOI)

- Directed edges represent citations (from citing to cited paper)

The resulting graph contained:

- 10,533,332 nodes

- 17,326,008 directed edges

This highlights the large-scale nature of the dataset and justifies the need for scalable representation methods such as node embeddings.

=== Graph-Based Feature Engineering
Two direct citation-based features were extracted per paper:

- incoming_citations_count: In-degree (number of times cited)

- outgoing_citations_count: Out-degree (number of references made)

These structural metrics were used in exploratory data analysis and included in traditional classifiers.

=== Node Embeddings
To represent each paper’s citation context more compactly, I trained node embeddings on the citation graph using ProNE (Probabilistic Network Embedding), a scalable spectral-based method. Configuration:

- Embedding dimension: 64

- Graph input: full citation graph

- Training output: low-dimensional vector per node

These embeddings serve as dense, learnable representations of each paper’s position and neighborhood in the citation network — similar to how word embeddings capture semantic similarity.

==== Embedding Visualization
To explore structural patterns, I used t-SNE to reduce the 64-dimensional embeddings to 2D for visualization. Each point represents a paper, color-coded by metadata attributes such as:

- Domain (see Figure @embedding1)

- Retraction status (see Figure @embedding2)

- Publication year, etc.

These visualizations provided insight into whether papers with similar characteristics (e.g. domain, fraud label) are grouped closely in the structural embedding space.



#figure(
  image("/images/emb by domain.png", width: 390pt),
  caption: [
    A t-SNE projection of ProNE node embeddings, colored by research domain.
  ]
)<embedding1>

#figure(
  image("/images/emb by retraction.png", width: 380pt),
  caption: [
    A t-SNE projection of ProNE node embeddings, colored by retraction status.
  ]
)<embedding2>

The resulting plot in @embedding1 shows clear separation between domains, with distinct clusters forming for papers in the Life Sciences, Physical Sciences, Health Sciences, and Social Sciences.

This indicates that the ProNE embeddings successfully capture high-level structural similarities within the citation network that align with scientific domains. For example, Life Sciences papers (purple) and Social Sciences papers (blue) are densely grouped in specific regions of the plot. This domain-specific clustering suggests that the citation patterns learned by the embedding model reflect not only graph topology but also the semantic structure of scientific discourse, as papers within the same domain tend to cite each other more frequently.

A notable cluster in the 2D t-SNE projection—visibly separated from the main embedding cloud (see green blob in @embedding2) was found to correspond to 1,682 papers. Upon inspection of their structural graph properties, all of these papers exhibited an in-degree of zero, meaning that they are never cited by any other paper in the graph. This indicates structural isolation, supporting the hypothesis that the blob reflects a disconnected subset of the citation network. 
These papers still include citations (mean out-degree = 105.3), but show extremely skewed citation behavior, with one paper citing over 24,000 others. Such patterns may indicate data anomalies, automatically generated references, or low-quality articles from paper mills. Their disconnected status may also explain the model’s difficulty in embedding them meaningfully, resulting in their collapse into a dense blob in the t-SNE plot.


=== Metadata Thresholding & One-Hot Encoding <onehot>

Several categorical metadata fields in the dataset, including Author, Institution, Country, Domain, and Field, contained hundreds or thousands of unique values. Many of these appeared only a handful of times, making them difficult to model and prone to overfitting.

To address this, I applied frequency-based thresholding and one-hot encoding.

==== Frequency Thresholding
For each categorical column, I grouped infrequent values into an "other" category. The thresholds were selected empirically to strike a balance between coverage and noise reduction:
- Top 100 authors
- Top 50 institutions
- Top 20 countries

All values below these thresholds were replaced with "other".

For example, the transformed column Field_threshold contains either the original field name or "other", depending on how frequently the field occurs in the dataset. This helps reduce model complexity while retaining meaningful distinctions.

The thresholds for author, institution, and country indicators were selected after analyzing the distribution of frequencies, which revealed a long-tail pattern with a few highly frequent entries and many rare ones.

==== One-Hot & Multi-Label Encoding
Fields like Author, Institution, and Country were originally stored as semicolon-separated strings, e.g.:

- Author: "Derek C. Angus; Tom van der Poll"

- Country: "Netherlands; United States"

These fields are multi-label and variable in length, which is incompatible with most machine learning algorithms.

To transform them into a usable format:

1. I counted the frequency of each unique entity.

2. I created binary indicator columns for the top entries (e.g., author_ETH, country_US), plus an "other" flag.

Each new feature takes the value 1 if the entity appears in a given paper, and 0 otherwise.

This approach preserves multi-label information while converting irregular text fields into a fixed-length, sparse binary matrix — ideal for structured classifiers.


#figure(
  table(
    columns: 3,
    table.header(
      [Field],
      [Threshold],
      [Resulting Features],
    ),

    [`Author`], [Top 100], [101 binary columns],
    [`Institution`], [Top 50], [51 binary columns],
    [`Country`], [Top 20], [21 binary columns],
    [`Field`], [50+ count], [One-hot or “other”],
    [`Domain`], [50+ count], [One-hot or “other”],
  ),
  caption: title-caption(
    [Metadata Thresholding and Resulting Feature Space],
    [Summary of thresholds applied for high-cardinality metadata fields and the resulting feature transformations.],
  ),
)<T:metadata_thresholds>


=== Creating Metadata Sentences for Text-Based Models

Since I planned to use transformer-based models like BERT or DeBERTa, I wanted to include structured metadata in a way that these models could understand. These models are designed to work with text, so I came up with the idea of turning the metadata into *natural language sentences*.

For each paper, I created a sentence that combines the most important metadata in a readable way. This included:

- the date the paper was written (`OriginalPaperDate`)
- the country or countries of the authors
- the institution or institutions
- the research domain (like "Physical Sciences")
- the research field (like "Computer Science")

I did this in *two versions*. One version used the original metadata values. The other version used the thresholded values, where rare countries or institutions were replaced with "other".

Here is an example using the original metadata:
_This paper was written on 06/10/2021 00:00 in China;Australia, at School of Information and Communication Technology, Griffith University, Nathan, QLD, Australia;College of Computer and Information, Hohai University, Nanjing, China, in the domain of Physical Sciences, covering the field of Computer Science._

And here is an example of a sentence using the thresholded values:
_This paper was written on 06/10/2021 00:00 in other, at other, in the domain of Physical Sciences, covering the field of Computer Science._

If some parts of the metadata were missing, I just left them out or replaced them with "other". 

This approach allowed me to give the models extra context without changing their architecture. It also made it possible to use metadata in the same way as the abstract or introduction, as text that the model could read and learn from.


== Train-Test Split

To evaluate my models fairly and ensure generalizability, I split my balanced dataset into a training set and a test set using an 80/20 ratio. Since the dataset contains two distinct classes (retracted and non-retracted papers), I avoided a simple random split and instead used a class-stratified method to ensure that both subsets remain balanced.

Specifically, I first divided the dataset by class: all retracted papers and all non-retracted ones. I then applied an 80/20 split *within each class*, resulting in 8,404 retracted and 8,404 non-retracted papers in the training set (16,808 total), and 2,101 of each in the test set (4,202 total). Finally, I shuffled both sets to eliminate any potential ordering bias.

All splits were performed before feature extraction and scaling to prevent data leakage. Although I focused primarily on balancing the retracted label, the distributions of other important attributes such as publication year, research domain, and research field were preserved as much as possible due to the within-class randomization strategy as shown on @split_retraction to @split_field.

This approach ensures that accuracy, AUC, and other evaluation metrics reported later are not skewed by class imbalance. It provides a reliable and representative foundation for training and evaluating classification models.

#figure(
  image("/images/Retraction Distribution Split.png", width: 380pt),
  caption: [
    Class Distribution Across Train/Test Splits.
  ]
)<split_retraction>

#figure(
  image("/images/Year Split.png", width: 380pt),
  caption: [
    Publication Year Distribution Across Splits.
  ]
)<split_year>

#figure(
  image("/images/Domain Split.png", width: 380pt),
  caption: [
    Research Domain Distribution in Training and Test Sets.
  ]
)<split_domain>

#figure(
  image("/images/Field Split.png", width: 380pt),
  caption: [
    Research Field Distribution Across Train/Test Splits.
  ]
)<split_field>


// here

== Analysis of Text Structure and Citation Features

To explore structural differences between retracted and non-retracted papers, I analyzed selected handcrafted features reflecting writing style and citation behavior. The goal was to uncover patterns that might help distinguish the two classes, and to ensure feature distributions are consistent across both training and test sets.


=== Text Structure Features
I visualized eight core text structure features derived from the abstract, such as character and word counts, sentence length, stopword ratio, digit and special character ratios, and the type-token ratio. These features are intended to capture different dimensions of writing style and complexity.

The distributions were plotted separately for retracted and non-retracted papers within both the training and test sets.

#figure(
  image("/images/Text Structure Split.png", width: 380pt),
  caption: [
    Key abstract-based text structure features, split by class and dataset partition 1.
  ]
)<textstructure1>

#figure(
  image("/images/Text Structure Split 2.png", width: 380pt),
  caption: [
    Key abstract-based text structure features, split by class and dataset partition 2.
  ]
)<textstructure2>



The boxplots show that retracted and non-retracted papers have largely similar distributions across all text features, confirming the consistency of the data split. Slightly elevated values for retracted papers in features like hc_09_digit_ratio and hc_10_special_char_ratio suggest subtle stylistic differences. Many features, especially those related to length, show long-tailed distributions with outliers indicating high variance in writing styles. One interesting pattern appears in the Type-Token Ratio (TTR): retracted papers consistently show lower TTR values across both training and test sets compared to non-retracted ones. This suggests that retracted papers may use less lexical variety, possibly indicating more repetitive, generic, or templated writing. This trend could reflect differences in writing quality or originality.

These findings are important because they show that writing style alone may not be sufficient to distinguish between retracted and non-retracted papers. However, small stylistic signals could still contribute useful predictive information when combined with other features.

=== Citation Features
In addition to the text-based features, I also examined citation-related metrics, namely incoming_citations_count and outgoing_citations_count. These features reflect how influential a paper is (via received citations) and how well-situated it is in the literature network (via outgoing references).

The boxplots in Figure @citationsplit highlight clear differences in citation behavior between retracted and non-retracted papers. Retracted papers receive noticeably fewer *incoming citations*, indicating they are less frequently cited by other researchers. This suggests reduced visibility and impact within the scientific community. A similar pattern emerges for *outgoing citations*, where retracted papers also tend to reference fewer sources. This may reflect weaker engagement with existing literature—potentially pointing to superficial scholarship, poor integration, or even synthetic content generation.


#figure(
  image("/images/Citation Split.png", width: 380pt),
  caption: [
    Citation Features by Split and Retraction Status.
  ]
)<citationsplit>

These findings imply that retracted papers are often *less integrated into the scholarly citation network*, even before accounting for more complex structural features. Such disconnection may be associated with lower research quality, questionable practices, or lack of academic recognition.


== Entity Distribution Analysis Across Splits and Classes

To assess representativeness and check for potential sources of bias, I analyzed the distribution of the most frequent categorical entities - authors, institutions, and countries —across the training and test sets. These features were previously converted into binary indicators for the most frequent values (see @T:metadata_thresholds).

For each entity type, I visualized the top 10 most common entries stratified by split (train, test) and class label (Yes = retracted, No = non-retracted). This resulted in four subplots per entity group.

Key Observations:
- Authors: The placeholder feature author_Other dominated across all subsets, reflecting the expected long-tail distribution. However, certain retracted authors such as Joachim Boldt and Yoshitaka Fujii consistently ranked among the most frequent entries in the retracted class. In contrast, the non-retracted class showed a broader distribution, with no single author as dominant.

- Institutions: inst_Other appeared most frequently overall, but clear trends were visible within known entries. Institutions such as Harvard University, University of Washington, and Stanford University were predominantly associated with non-retracted papers. Retracted papers more often referenced a broader range of institutions, including King Saud University and King Abdulaziz University, which occurred mostly in the retracted class.

- Countries: The retracted class was strongly dominated by China, followed by India, Saudi Arabia, and Germany. In contrast, non-retracted papers were most often affiliated with United States, United Kingdom, Canada, and Australia. These geographic trends may reflect real-world disparities in retraction rates, research practices, or publication volume.


#figure(
  image("/images/Country Split.png", width: 380pt),
  caption: [
    Top Countries by Split and Retraction Status.
  ]
)<country_split>

These findings confirm that certain authors, institutions, and countries are disproportionately represented in one class. While this may reflect real-world retraction dynamics or underlying publication dynamics, it also raises the potential for bias. Classifiers trained on these features might inadvertently overfit to spurious associations unless such effects are controlled.

Encouragingly, the distributions remained consistent between training and test sets, validating the stratified sampling procedure and supporting the use of these entity-based features in downstream modeling.


// here

== Feature Selection and Significance Analysis for Logistic Regression

To determine which input features meaningfully contribute to the prediction of retracted scientific publications—beyond traditional text representations such as TF-IDF—I conducted a comprehensive feature selection and significance analysis using logistic regression on the training dataset. Logistic regression is particularly well-suited for this purpose due to its interpretability, but it is sensitive to multicollinearity and requires all input features to be numerical and fixed-dimensional. As such, careful feature preprocessing, encoding, and grouping were performed prior to any statistical evaluation.


=== Feature Types Considered
The dataset contained a broad and diverse set of features derived from text, metadata, citation behavior, and graph-based enrichment. For this analysis, only numerical and binary features were considered, as logistic regression requires fixed-dimensional, numerical inputs. The selected features were grouped into the following categories:

- *Handcrafted Linguistic Features*: A total of 60 handcrafted features were engineered to quantify structural and stylistic aspects of the paper. These include: 
  - Abstract features (hc prefix): word count, sentence length, etc.
  - Full-text features (hc_ft prefix): extracted using the same logic as the abstract features, but applied to the entire available text (FullText).
  This separation allows comparison between summary-level and full-document writing characteristics.

- *Citation and Network Features*: These include incoming_citations_count and outgoing_citations_count. Both features capture the paper’s position in the citation network and reflect scholarly influence.

- *Semantic Similarity Features*: These features quantify semantic distances between a paper’s text and its referenced works using sentence embeddings:
  - mean/max_citation_context_to_cited_abstract_l2_distance_y

  - mean/max_abstract_to_cited_abstract_l2_distance_y
  Higher distances may signal inconsistent or superficial citation behavior.

- *Metadata Counts*: These numeric features summarize the scale and diversity of collaboration: 
  - num_authors
  - num_institutions
  - num_countries

- *Graph Embedding Features (Node Embeddings)*: I used 64-dimensional node embeddings derived from the citation graph, where each node represents a paper. These embeddings, stored in columns "0" to "63" help represent a paper's role in the scientific graph independently of its textual content.

- *Binary Encoded Indicators*: To encode categorical metadata, the most frequent values (Authors, Institutions, Countries) were transformed into binary variables

- *Domain and Field Variables*: These were one-hot encoded to create binary features (e.g., Domain_threshold_Life Sciences, Field_threshold_Medicine).

This comprehensive selection allowed for a rich combination of textual, structural, semantic, and contextual signals to be analyzed in a consistent, interpretable format suitable for logistic regression.

    
=== Preprocessing and Scaling

All selected features were numerical or binary after preprocessing. Before model training, missing values were replaced with zeros, and all features were scaled using `StandardScaler`. This ensures that features with larger numeric ranges do not disproportionately influence the logistic regression weights.


=== Significance Estimation via Logistic Regression

To quantify the predictive value of individual input features, I conducted a significance analysis using logistic regression. Given that logistic regression is sensitive to collinearity and yields interpretable coefficients, it is well suited for this type of feature evaluation.

To ensure robustness and reduce the impact of random variation, I repeated the analysis five times with different random seeds (0, 1, 42, 100, 1234). Each run involved an 80/20 stratified train-test split based on the target variable retracted.

For each of the five trained models, I extracted the learned feature coefficients and computed the following statistics:
- Mean coefficient: The average weight assigned to each feature across runs, indicating the direction and strength of its overall association with retraction.
- Standard deviation: The variability of the coefficient across seeds, used to assess estimation stability.
- t-like score: A stability-adjusted importance measure, calculated as the ratio of mean to standard deviation. This highlights features that are both influential and consistently weighted across different splits.

This step aimed to identify not only strong individual predictors of retraction but also the most informative feature groups for downstream modeling. To support interpretability and robustness, features were ranked by the absolute value of their mean logistic regression coefficient, providing a clear metric of predictive impact. I manually selected the most stable and influential features by prioritizing those with high mean coefficients, low variance across runs, and consistency with domain knowledge. This process informs which features should be retained and helps distinguish between informative patterns and redundant or noisy signals.


=== Feature Significance and Groupwise Performance Analysis

To evaluate the contribution of individual features and feature groups to retraction prediction, I performed two complementary analyses. The first estimated the significance of individual features using logistic regression coefficients. The second assessed the standalone predictive power of entire feature groups through repeated model evaluation.

==== Individual Feature Significance

Using logistic regression trained with five different random seeds (80/20 stratified split). The top-ranked features as shown in @sig_test reflect both strong positive and negative associations with retracted papers:
- `incoming_citations_count` and `outgoing_citations_count`, both with strong negative coefficients. This suggests that retracted papers tend to be cited less frequently and reference fewer other papers, indicating a weaker position in the citation network.
- `mean_citation_context_to_cited_abstract_l2_distance_y` and `max_abstract_to_cited_abstract_l2_distance_y`, which had strong positive coefficients. These features measure semantic divergence between citing contexts and cited works, potentially reflecting incoherence or misuse of references.
- `Year` also emerged as one of the top features. Its inclusion reflects temporal patterns in retraction, possibly linked to changes in publication practices, fraud detection capabilities, or evolving scientific standards. Since the dataset was not stratified by year, this effect could likely be a reflection of class imbalance.
- `num_authors`, which showed a strong negative correlation with retraction. Papers with fewer authors may lack collaborative oversight.
- Handcrafted features such as `hc_ft_27_long_word_ratio` and `hc_ft_28_short_word_ratio`, showing that lexical properties of text are also predictive.
- Specific authors and countries, such as `author_James E Hunton`, `author_Diederik A Stapel`, and `country_Korea, Republic of`, also emerged as important binary indicators. These results align with known cases of academic misconduct.
- Several field-level indicators (`Field_threshold_Medicine`, `Field_threshold_Computer Science`, etc.) and linguistic markers (`type_token_ratio`, `adj_count`, `stopword_ratio`) also contributed meaningfully to the prediction task.

#figure(
  image("/images/Significance Testing.png", width: 380pt),
  caption: [
    Top Most Influential Features (LogReg).
  ]
)<sig_test>


This detailed coefficient-based ranking provides a valuable foundation for interpreting the influence of individual features and understanding their role in differentiating retracted and non-retracted papers.

==== Groupwise Performance Comparison

To complement individual feature analysis, I evaluated each feature group in isolation by training five logistic regression models per group using the same seeds and evaluation procedure. Mean classification accuracy was used to assess predictive strength:

- *Citation (0.958)*: The features capturing citation volume proved to be the most informative group by far. This highlights how citation context reflects credibility and influence.
- *Country binaries (0.834)*: The country of authorship appears to be a strong differentiator. This may reflect known biases or systemic issues in publishing quality across regions.
- *Handcrafted (abstract) (0.809)*: Linguistic and structural properties of the abstract carried substantial signal, confirming that writing style and structure are informative indicators.
- *Graph Embedding Features (0.780)*: Graph-based semantic representations of papers, derived from the citation network, provided strong performance and captured underlying structural patterns.
- *Handcrafted (full text) (0.734)*: Text statistics derived from the full paper performed moderately well but slightly worse than those from the abstract, possibly due to noise from less curated sections.
- *Similarity features (0.719)*: L2 distance-based measures of semantic consistency across references and abstracts were also useful, but secondary to citation volume itself.
- *Meta counts (0.667)*: The number of authors, institutions, and countries per paper provided moderate signal, supporting the idea that collaboration and scope influence paper reliability.
- *Field/domain dummies (0.553)*: Encoded fields and disciplines contributed only weakly on their own, possibly due to redundancy with other features or limited resolution.
- *Author binaries (0.546)*: While individual authors like known fraudsters were important, using the entire binary vector in isolation did not yield high predictive performance.
- *Institution binaries (0.525)*: Similarly, institution information alone was not sufficient for accurate classification, though certain institutions may still hold signal when combined with others.

These results confirm that citation-based, geographic, and linguistic features are the most informative when used independently. While some binary indicators (e.g., authors, institutions) are useful in isolated cases, they offer limited generalization and lower standalone performance.

//here



=== Feature Selection Decisions

Based on the combination of *individual feature influence*, *group-level predictive accuracy*, and *domain-specific generalizability*, I made the following decisions:

==== Retained Feature Groups

- *Citation Features*: These features demonstrated the strongest individual impact and yielded the highest group accuracy (0.958). They represent well-established network centrality concepts and generalize well across domains and time.

- *Similarity Features*: These features quantify semantic coherence between a paper and its citations. Their consistent and interpretable contribution to prediction makes them valuable, even beyond individual coefficients.

- *Handcrafted Abstract Features*: Features such as `hc_01_word_count` and `hc_25_adj_count` showed moderate to strong individual coefficients and belonged to a group with high accuracy (0.809). These features reflect linguistic and structural qualities of abstracts and are interpretable and generalizable.

- *Handcrafted Full-Text Features*: Despite slightly lower group accuracy (0.734), these features were retained because they extend the analysis to the complete document and had several individually strong contributors (e.g., `hc_ft_27_long_word_ratio`). They complement the abstract features and increase model robustness.

- *Graph-Based Embeddings*: These 64-dimensional node embeddings (columns 0–63) capture structural position and neighborhood similarity in the citation graph. While not directly interpretable, they contributed moderate predictive power (accuracy: 0.780) and complement other structural and semantic features.

- *Meta Counts*: These provide high-level information about the scale and diversity of collaboration. Although their coefficients were smaller, they showed moderate group performance and strong generalizability.

- *Country Binaries*: This group (e.g., `country_United States`, `country_China`) achieved a high standalone accuracy of 0.834. Countries often capture systemic research differences and were shown to generalize well.

- *Top 10 Author Binary Features*: Rather than retaining all 100+ `author_` features, I selected only the 10 authors with the strongest and most stable coefficients. These included individuals like `author_Joachim Boldt` and `author_Diederik A Stapel`, who are known for repeated retractions. This balances interpretability, precision, and generalizability while reducing overfitting risk.

- *Year*: The publication year exhibited a strong and stable negative coefficient (mean = -1.695, t-like score = -33.4), indicating that older papers are more likely to be retracted. While this makes intuitive sense—retractions take time—it also introduces the risk of temporal leakage. Year was therefore included for modeling purposes and interpretability, but models that include Year must be interpreted cautiously, especially in real-world deployment scenarios.

==== Dropped Feature Groups

- *Author Binaries (except top 10)*
  The dataset originally included over 100 binary features indicating the presence of specific authors in a given paper. While a small subset of these features—such as those corresponding to known fraudsters like Joachim Boldt or Yoshitaka Fujii—exhibited strong and stable coefficients, the overall group achieved low predictive performance (mean accuracy of 0.546 when used alone). Their distribution is extremely sparse, with many authors occurring only once or twice. This encourages overfitting. Additionally, reliance on known author identities hinders the model’s ability to flag retractions by previously unseen or future authors. For these reasons, only the ten most influential authors  were retained. 
  
- *Institution Binaries*
  Despite initial inclusion of 50+ institutional indicators, this group yielded the weakest performance (accuracy: 0.525). Sparse occurrence and inconsistent predictive value made them a poor choice for generalizable modeling. All institution binaries were excluded.

- *Field and Domain Dummies*
  Broad academic categories like Field and Domain added limited value (accuracy: 0.553) and overlapped with more informative features like text embeddings or linguistic patterns. Their low granularity and weak standalone performance led to their exclusion from the final set.

In total, the refined logistic regression feature set contains 167 features, offering a balance of interpretability, predictive strength, and generalization potential for the downstream classification task.

#figure(
  table(
    columns: 3,
    align: left,
    table.header(
      [Feature Group], [Count], [Description],
    ),
    [Citation], [2], [`incoming_citations_count`, `outgoing_citations_count`],
    [Similarity], [4], [`mean/max_..._l2_distance_y` between citation contexts and cited abstracts],
    [Handcrafted Abstract], [30], [Linguistic features from the abstract (`hc_...`)],
    [Handcrafted Fulltext], [30], [Linguistic features from the full text (`hc_ft_...`)],
    [Embeddings], [64], [ProNE node embeddings: columns `"0"` to `"63"`],
    [Meta Counts], [3], [`num_authors`, `num_institutions`, `num_countries`],
    [Country Binaries], [23], [One-hot encoded country indicators (`country_...`)],
    [Top 10 Authors], [10], [Most influential `author_...` binaries],
    [Year], [1], [Publication year (standardized)],
    [Target], [1], [`retracted` (binary label)]
  ),
  caption: title-caption(
    [Final Logistic Regression Feature Set],
    [This table summarizes all retained feature groups, their size, and descriptions, used in the final logistic regression setup.]
  )
)<finalfeatures>

== Significance Testing of Different Text Fields

To assess which textual components are most informative for predicting retractions, I conducted significance testing using a standard fine-tuned transformer model (`distilbert-base-uncased`) on three separate fields: `Abstract`, `FullText`, and `metadata_sentences`. The goal was to evaluate their individual predictive power with regard to the retraction label using consistent training and evaluation settings.

The model was fine-tuned on each field separately using 5 different random seeds to ensure robustness. Each training run used a stratified 80/20 train-test split, and evaluation was based on classification accuracy as seen in @textfieldaccuracy.


#figure(
  table(
    columns: 3,
    align: left,
    table.header(
      [Text Field], [Mean Accuracy], [Standard Deviation],
    ),
    [`metadata_sentences`], [1.0000], [0.0000],
    [`Abstract`], [0.9164], [0.0026],
    [`FullText`], [0.7526], [0.0011],
  ),
  caption: title-caption(
    [Accuracy of Text Fields in Transformer-Based Retraction Prediction],
    [Mean and standard deviation of classification accuracy for three text inputs using a fine-tuned transformer model (`distilbert-base-uncased`) across five seeds.]
  )
)<textfieldaccuracy>

=== Interpretation
- *metadata_sentences (Accuracy = 1.0000)*: This field yielded perfect accuracy across all runs, indicating likely label leakage. Manual inspection revealed that the field includes descriptive metadata such as country, institution, and publication year—attributes that are strongly correlated with retraction labels in the dataset. While effective in this context, such prediction is non-generalizable and misleading. As a result, this field was excluded from further text-based modeling to avoid exploiting bias or dataset artifacts.

- *Abstract (Accuracy = 91.6%)*: Abstracts provided high predictive power with low variance, making them the most reliable textual input. They contain domain-relevant information and subtle linguistic cues, offering a good balance of informativeness and generalizability. Accordingly, the abstract was selected as the main input for subsequent transformer-based modeling.

- *FullText (Accuracy = 75.3%)*: Despite containing more raw information, the full text performed significantly worse. This may be due to input truncation (limited to 256 tokens), structural variability, or noise from boilerplate sections. Without additional preprocessing (e.g., summarization or section filtering), full-text inputs appear suboptimal for this task.

=== Conclusion

Not all text fields are equally suitable for retraction prediction. Metadata-derived text can artificially inflate performance through label leakage, while full texts pose challenges due to length and noise. Abstracts, in contrast, offer concise, domain-specific content with high predictive value and were thus selected as the primary input for robust and interpretable modeling.








