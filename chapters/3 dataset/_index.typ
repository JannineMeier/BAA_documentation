#import "/template/_helpers.typ": todo
#import "/template/_helpers.typ": title-caption
#import "@preview/acrostiche:0.5.0": acr, acrfull

= Data Sources and Preprocessing

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

// heeeeeeeeeeeeeeeere
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

=== Embedding Visualization
To explore structural patterns, I used t-SNE to reduce the 64-dimensional embeddings to 2D for visualization. Each point represents a paper, color-coded by metadata attributes such as:

- Domain (see Figure @embedding1)

- Retraction status (see Figure @embedding2)

- Publication year, etc.

These visualizations provided insight into whether papers with similar characteristics (e.g. domain, fraud label) are grouped closely in the structural embedding space.



#figure(
  image("emb by domain.png", width: 390pt),
  caption: [
    A t-SNE projection of ProNE node embeddings, colored by research domain.
  ]
)<embedding1>

#figure(
  image("emb by retraction.png", width: 380pt),
  caption: [
    A t-SNE projection of ProNE node embeddings, colored by retraction status.
  ]
)<embedding2>

The resulting plot in @embedding1 shows clear separation between domains, with distinct clusters forming for papers in the Life Sciences, Physical Sciences, Health Sciences, and Social Sciences.

This indicates that the ProNE embeddings successfully capture high-level structural similarities within the citation network that align with scientific domains. For example, Life Sciences papers (purple) and Social Sciences papers (blue) are densely grouped in specific regions of the plot. This domain-specific clustering suggests that the citation patterns learned by the embedding model reflect not only graph topology but also the semantic structure of scientific discourse, as papers within the same domain tend to cite each other more frequently.

A notable cluster in the 2D t-SNE projection—visibly separated from the main embedding cloud (see green blob in @embedding2) was found to correspond to 1,682 papers. Upon inspection of their structural graph properties, all of these papers exhibited an in-degree of zero, meaning that they are never cited by any other paper in the graph. This indicates structural isolation, supporting the hypothesis that the blob reflects a disconnected subset of the citation network. 
These papers still include citations (mean out-degree = 105.3), but show extremely skewed citation behavior, with one paper citing over 24,000 others. Such patterns may indicate data anomalies, automatically generated references, or low-quality articles from paper mills. Their disconnected status may also explain the model’s difficulty in embedding them meaningfully, resulting in their collapse into a dense blob in the t-SNE plot.


== Metadata Thresholding & One-Hot Encoding <onehot>

Several categorical metadata fields in the dataset, including Author, Institution, Country, Domain, and Field, contained hundreds or thousands of unique values. Many of these appeared only a handful of times, making them difficult to model and prone to overfitting.

To address this, I applied frequency-based thresholding and one-hot encoding.

=== Frequency Thresholding
For each categorical column, I grouped infrequent values into an "other" category. The thresholds were selected empirically to strike a balance between coverage and noise reduction:
- Top 100 authors
- Top 50 institutions
- Top 20 countries

All values below these thresholds were replaced with "other".

For example, the transformed column Field_threshold contains either the original field name or "other", depending on how frequently the field occurs in the dataset. This helps reduce model complexity while retaining meaningful distinctions.

The thresholds for author, institution, and country indicators were selected after analyzing the distribution of frequencies, which revealed a long-tail pattern with a few highly frequent entries and many rare ones.

=== One-Hot & Multi-Label Encoding
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


/// bis hieeeeeeeeeeeeeeeeeer
== Creating Metadata Sentences for Text-Based Models

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

// here
== Similarity Score Features
https://github.com/Christof93/citation_semantic_congruence
to do: neu schreiben und evtl grafik hinzufügen
As part of the dataset, I also included several similarity-based features that were developed by Christof. These features aim to measure how similar the content of a paper is to the papers it cites. This can help detect cases of copied text, minimal paraphrasing, or even automatically generated content that heavily borrows from previous work.

The similarity scores are based on the L2 (Euclidean) distance between sentence embeddings. These embeddings are vector representations of texts like abstracts or citation contexts. A lower distance means that the two texts are more similar in meaning and language.

The following four features were included:

- mean_citation_context_to_cited_abstract_l2_distance_y
  Average distance between the citation context and the abstract of the cited paper. This shows how close a citation statement is to the original content.

- max_citation_context_to_cited_abstract_l2_distance_y
  Maximum distance between any citation context and a cited abstract. It helps identify outliers where the citation may be unrelated.

- mean_abstract_to_cited_abstract_l2_distance_y
  Average distance between the full abstract of the paper and all cited abstracts. This gives a general idea of how similar the citing paper’s abstract is to the content it references.

- max_abstract_to_cited_abstract_l2_distance_y
  Maximum distance between the abstract of the paper and any one cited abstract. This can flag major mismatches or content that deviates significantly from its sources.

Unfortunately, not all cited papers had abstracts available in OpenAlex or other sources, so there are quite a few missing values for these features. Out of the full dataset, only about 8,000 papers have complete similarity scores, while approximately 12,000 papers are missing these values. Among the 8,000 available examples, 2,000 are non-retracted and 6,000 are retracted.

Despite the imbalance and missing data, I will still consider these features for testing purposes. While the smaller subset might make modeling more difficult, especially when evaluating fairness or generalizability, it can still provide useful insights into whether similarity patterns differ between retracted and non-retracted papers.

== Train-Test Split with Class-Symmetric Distribution
To evaluate my models fairly and ensure generalizability, I split my balanced dataset into a training set and a test set using an 80/20 ratio. Since the dataset contains two distinct classes (retracted and non-retracted papers), I did not use a simple random split. Instead, I made sure that both the train and the test set contain equal numbers of retracted and non-retracted papers so that the classification task remains balanced in both phases of model development.

To achieve this, I first separated the dataset into two groups based on the retracted label. One group contained all retracted papers (labeled as "Yes") and the other group included all non-retracted papers (labeled as "No"). I then applied an 80/20 split within each group separately, which allowed me to preserve the class distribution exactly. After splitting both groups, I combined the training portions of each into one final training set and did the same for the test set. Finally, I shuffled both sets to avoid any ordering bias.

This method ensures that both the training and test sets contain the same number of positive and negative examples and that the class balance is consistent throughout the entire modeling process. By doing this, I avoid giving the model an advantage by training or evaluating on an imbalanced set, which could otherwise lead to misleading performance metrics.

Although I primarily focused on balancing the retracted label, the distributions of other relevant features such as Field, Domain, and Year were also preserved as much as possible since the splits were performed randomly within each class. This approach provides a solid and reliable foundation for training and evaluating classification models.

#image("Retraction Distribution Split.png")

#image("Year Split.png")

#image("Domain Split.png")

#image("Field Split.png")


== Analysis of Text Structure and Citation Features
To gain a better understanding of how retracted and non-retracted papers differ in terms of writing style and citation behavior, I analyzed the distribution of a selection of handcrafted features across the training and test sets. The goal was to assess whether there are noticeable structural patterns in the texts or citation statistics that differ between retracted and non-retracted papers, and whether these patterns are consistent across both data splits.

- Text Structure Features
I visualized eight core text structure features derived from the abstract, such as character and word counts, sentence length, stopword ratio, digit and special character ratios, and the type-token ratio. These features are intended to capture different dimensions of writing style and complexity.

The distributions were plotted separately for retracted and non-retracted papers within both the training and test sets.

#image("Text Structure Split.png")

#image("Text Structure Split 2.png")

Across all features, the boxplots revealed that:

The overall distributions are quite similar between splits, confirming that the data split was done consistently.

Retracted papers tend to have slightly higher values for some stylistic features such as hc_09_digit_ratio and hc_10_special_char_ratio, although the differences are relatively subtle.

Most features exhibit a long-tailed distribution with a high number of outliers, especially in length-related metrics like character and sentence count. This suggests a large variance in abstract size and writing style across the dataset.

These findings are important because they show that writing style alone may not be sufficient to distinguish between retracted and non-retracted papers. However, small stylistic signals could still contribute useful predictive information when combined with other features.

- Citation Features
In addition to the text-based features, I also examined citation-related metrics, namely incoming_citations_count and outgoing_citations_count. These features reflect how influential a paper is (via received citations) and how well-situated it is in the literature network (via outgoing references).

#image("Citation Split.png")

The boxplots revealed that:

Retracted papers show slightly higher variance in both citation counts compared to non-retracted ones.

A small number of papers in both classes are extreme outliers with very high citation counts, which skews the distribution heavily.

On average, there does not appear to be a large difference between retracted and non-retracted papers in terms of citation counts alone.

These insights indicate that while citation counts may carry some signal, especially in combination with network-based features like citation patterns, they are not strong standalone indicators of retraction.

Overall, this analysis helped validate that both splits reflect a consistent distribution of key writing and citation characteristics, and that the features chosen are diverse and potentially informative for downstream modeling tasks.



== Entity Distribution Analysis Across Splits and Classes

To further examine the representativeness and potential biases within my training and test sets, I analyzed the top 10 most frequently occurring entries for the categorical entity features: authors, institutions, and countries. These were previously transformed into binary indicator columns for high-frequency entries during feature engineering.

For each of these feature groups, I plotted the top 10 entities separately for each split (train, test) and retraction class (Yes, No). This resulted in four subplots per group, enabling a detailed comparison of entity presence across subsets of the dataset.

The results revealed several important patterns:

- Authors: Across both training and test sets, the placeholder author_Other was by far the most frequent entry, which was expected due to the long-tail distribution of author names. However, certain retracted authors such as Joachim Boldt and Yoshitaka Fujii consistently appeared among the top entries in the Yes class, indicating a strong class-specific presence. In contrast, the No class contained a more diverse spread of authors, with lower individual counts.

- Institutions: Similar to authors, inst_Other dominated all subsets. Notably, institutions such as Harvard University, University of Washington, and Stanford University were frequently represented in the non-retracted class (No), especially in the training set. Retracted papers, on the other hand, were more commonly associated with a broader range of institutions, many of which appeared only in the Yes class, such as departments from King Saud University or King Abdulaziz University.

- Countries: The country distribution showed clear geographic trends. China dominated the retracted class, while the United States was the most frequent in the non-retracted class. Other countries such as India, Germany, and Saudi Arabia were also prevalent in the Yes class, whereas United Kingdom, Canada, and Australia were more frequent in the No class.
#image("Country Split.png")

This analysis confirmed that certain authors, institutions, and countries are disproportionately represented in either the retracted or non-retracted class. These patterns may reflect real-world retraction dynamics or underlying publication patterns, but they also highlight the importance of controlling for such features during model training to prevent unintended bias or overfitting.

The visualization also showed that the entity distributions were largely consistent between training and test sets, supporting the validity of the stratified split and the use of these features in downstream modeling.


== Feature Selection and Significance Analysis for Logistic Regression

To identify which input features meaningfully contribute to the prediction of retracted scientific publications (neben tfidf von textstpcken), I conducted a thorough feature selection and significance evaluation on my train dataset using logistic regression. Since logistic regression relies on numerical and interpretable features and is sensitive to multicollinearity, careful preprocessing and feature grouping were essential steps before conducting any statistical analysis.

=== Feature Types Considered

The dataset contained a large number of diverse features, including raw text, categorical metadata, numerical statistics, and engineered features. Only numerical and binary features were considered in this stage, as logistic regression requires fixed-dimensional, numerical input.

The selected features fall into the following main categories:

1. *Handcrafted Features (Abstract)*
   These are 30 linguistic and structural features extracted from the abstract section of each paper. They include measures such as sentence count, average sentence length, stopword ratio, type-token ratio, passive constructions, lexical density, punctuation frequency, and more. These features were prefixed with `hc_`.

2. *Handcrafted Features (Full Text)*
   Another set of 30 features were extracted using the same linguistic logic but applied to the entire available text of the publication (`FullText`). These are prefixed with `hc_ft_`.

3. *Citation and Network Features*
   The features in this group include:

   - `incoming_citations_count`: Number of times the paper has been cited.
   - `outgoing_citations_count`: Number of references made by the paper.

4. *Semantic Similarity Features*
   These features capture how semantically close the citing context or abstract of a paper is to the cited papers:

   - `mean_citation_context_to_cited_abstract_l2_distance_y`
   - `max_citation_context_to_cited_abstract_l2_distance_y`
   - `mean_abstract_to_cited_abstract_l2_distance_y`
   - `max_abstract_to_cited_abstract_l2_distance_y`

5. *Metadata Counts*
   To describe author-level complexity and international collaboration, I included:

   - `num_authors`
   - `num_institutions`
   - `num_countries`

6. *Text Embedding Features (TF-IDF or SBERT)*
   I used 64 dense numerical features that represent the semantic content of a paper. These could be TF-IDF vectors or sentence embeddings from models like SBERT, stored in columns `0` to `63`.

7. *Binary Encoded Author Indicators*
   Based on the top 100 most common authors in the dataset, I added binary features such as `author_Joachim Boldt` or `author_Wei Zhang` indicating whether a given author was part of a paper.

8. *Binary Encoded Institution Indicators*
   A similar process was used for the top 50 institutions, adding features such as `inst_Harvard University` or `inst_University of Washington`.

9. *Binary Encoded Country Indicators*
   For the top 20 most common countries, binary features like `country_United States` or `country_China` were added.

10. *Domain and Field Information*
    Originally present as strings, the `Domain_threshold` and `Field_threshold` columns were transformed into dummy variables using one-hot encoding. Each unique value was converted into a binary feature, such as `Domain_threshold_Health Sciences` or `Field_threshold_Medicine`.
    
=== Preprocessing and Scaling

All selected features were numerical or binary after preprocessing. Before model training, missing values were replaced with zeros, and all features were scaled using `StandardScaler`. This ensures that features with larger numeric ranges do not disproportionately influence the logistic regression weights.


=== Significance Estimation via Logistic Regression

To evaluate the contribution of each feature, I applied logistic regression five times using different random seeds (0, 1, 42, 100, 1234) to ensure the robustness of coefficient estimates. Each run involved an 80/20 train-test split with stratification based on the target variable `retracted`. For each trained model, I extracted the learned coefficients and computed:

- The *mean* coefficient per feature across all runs.
- The *standard deviation* of the coefficients.
- A *t-like score* defined as mean / standard deviation to assess stability and relative importance.

Features were then ranked by the *absolute value of their mean coefficient*, which reflects how strongly and consistently they contribute to the prediction of retraction status.

=== Rationale

The goal of this step was not only to identify strong individual predictors but also to understand which groups of features hold the most information about fraudulent publications. This analysis helps determine which feature types should be prioritized in more complex models (e.g., neural networks or graph-based models) and which ones may be redundant or noisy. It also informs model interpretability by highlighting interpretable features, such as certain stylistic markers or well-known retracted authors.

In the next step, I will interpret the ranking and performance of the top features and feature groups in more detail. This will include both individual feature importance as well as group-level comparisons based on classification accuracy.

=== Feature Significance and Groupwise Performance Analysis

After selecting and preparing a broad set of features from various categories, I conducted two levels of analysis to evaluate their contribution to the prediction of scientific retractions. The first focused on estimating individual feature importance using logistic regression. The second assessed the predictive power of entire feature groups using repeated model evaluation.

==== Individual Feature Significance

To assess the influence of individual features, I trained logistic regression models across five different random seeds using an 80/20 split. Each model was trained with all selected features, including handcrafted text statistics, semantic similarity scores, citation counts, binary author/institution/country encodings, and more. I extracted the model coefficients for each run and computed:

- The mean coefficient per feature
- The standard deviation of the coefficients
- A t-like stability score defined as the ratio of mean to standard deviation
- The absolute mean as an indicator of overall influence (regardless of direction)

The top-ranked features reflect both strong positive and negative associations with retracted papers. 

#image("Significance Testing.png")
Notably, the top 10 features included:

- `incoming_citations_count` and `outgoing_citations_count`, both with strong negative coefficients. This suggests that retracted papers tend to be cited less frequently and reference fewer other papers, indicating a weaker position in the citation network.
- `mean_citation_context_to_cited_abstract_l2_distance_y` and `max_abstract_to_cited_abstract_l2_distance_y`, which had strong positive coefficients. These features measure semantic divergence between citing contexts and cited works, potentially reflecting incoherence or misuse of references.
- `Year` also emerged as one of the top features. Its inclusion reflects temporal patterns in retraction, possibly linked to changes in publication practices, fraud detection capabilities, or evolving scientific standards. Since the dataset was not stratified by year, this effect could likely be a reflection of class imbalance.
- `num_authors`, which showed a strong negative correlation with retraction. Papers with fewer authors may lack collaborative oversight.
- Handcrafted features such as `hc_ft_27_long_word_ratio` and `hc_ft_28_short_word_ratio`, showing that lexical properties of text are also predictive.
- Specific authors and countries, such as `author_James E Hunton`, `author_Diederik A Stapel`, and `country_Korea, Republic of`, also emerged as important binary indicators. These results align with known cases of academic misconduct.

Several field-level indicators (`Field_threshold_Medicine`, `Field_threshold_Computer Science`, etc.) and linguistic markers (`type_token_ratio`, `adj_count`, `stopword_ratio`) also contributed meaningfully to the prediction task.

This detailed coefficient-based ranking provides a valuable foundation for interpreting the influence of individual features and understanding their role in differentiating retracted and non-retracted papers.

==== Groupwise Performance Comparison

To complement the analysis of individual feature importance, I evaluated the predictive power of each feature group in isolation. This helped to identify which types of features carry the most information when used alone. For this purpose, I trained logistic regression models five times per group, using the same seeds and evaluation setup as before. The results are summarized below:

- *Citation (0.958)* — The three features capturing citation volume proved to be the most informative group by far. This highlights how citation context reflects credibility and influence.
- *Country binaries (0.834)* — The country of authorship appears to be a strong differentiator. This may reflect known biases or systemic issues in publishing quality across regions.
- *Handcrafted (abstract) (0.809)* — Linguistic and structural properties of the abstract carried substantial signal, confirming that writing style and structure are informative indicators.
- *Embeddings (0.780)* — Semantic vector representations of the text (TF-IDF or SBERT) were also effective, although less so than citation or country-based features.
- *Handcrafted (full text) (0.734)* — Text statistics derived from the full paper performed moderately well but slightly worse than those from the abstract, possibly due to noise from less curated sections.
- *Similarity features (0.719)* — L2 distance-based measures of semantic consistency across references and abstracts were also useful, but secondary to citation volume itself.
- *Meta counts (0.667)* — The number of authors, institutions, and countries per paper provided moderate signal, supporting the idea that collaboration and scope influence paper reliability.
- *Field/domain dummies (0.553)* — Encoded fields and disciplines contributed only weakly on their own, possibly due to redundancy with other features or limited resolution.
- *Author binaries (0.546)* — While individual authors like known fraudsters were important, using the entire binary vector in isolation did not yield high predictive performance.
- *Institution binaries (0.525)* — Similarly, institution information alone was not sufficient for accurate classification, though certain institutions may still hold signal when combined with others.

These results reveal that citation-based and geographic features are the most discriminative when considered independently. Linguistic characteristics, semantic coherence, and topical metadata also contribute valuable signal. On the other hand, simple binary encodings of authors or institutions, though informative in specific cases, do not generalize well in isolation.

Excellent — here's a detailed, academic-style documentation section explaining your **feature selection** decisions, based on statistical significance, generalizability, and empirical model performance. This is structured and written for inclusion in your thesis or report.

 Feature Selection for Logistic Regression

To ensure that my logistic regression model remains interpretable, performant, and generalizable to unseen data (such as new authors, institutions, or papers), I applied a multi-step feature selection strategy grounded in empirical evidence and established statistical reasoning.

=== Feature Selection Decisions

Based on the combination of *individual feature influence*, *group-level predictive accuracy*, and *domain-specific generalizability*, I made the following decisions:

==== Retained Feature Groups

- *Citation Features*
  (`incoming_citations_count`, `outgoing_citations_count`) 
  These features demonstrated the strongest individual impact and yielded the highest group accuracy (0.958). They represent well-established network centrality concepts and generalize well across domains and time.

- *Similarity Features*
  (`mean/max_abstract_to_cited_abstract_l2_distance`, `mean/max_citation_context_to_cited_abstract_l2_distance`)
  These features quantify semantic coherence between a paper and its citations. Their consistent and interpretable contribution to prediction makes them valuable, even beyond individual coefficients.

- *Handcrafted Abstract Features*
  Features such as `hc_01_word_count` and `hc_25_adj_count` showed moderate to strong individual coefficients and belonged to a group with high accuracy (0.809). These features reflect linguistic and structural qualities of abstracts and are interpretable and generalizable.

- *Handcrafted Full-Text Features*
  Despite slightly lower group accuracy (0.734), these features were retained because they extend the analysis to the complete document and had several individually strong contributors (e.g., `hc_ft_27_long_word_ratio`). They complement the abstract features and increase model robustness.

- *Embeddings (TF-IDF/SBERT-based)*
  These semantic representations (columns `0`–`63`) capture latent meaning and contextual similarity. Though less interpretable, their performance and generalization capacity (accuracy: 0.780) justify their inclusion.

- *Meta Counts*
  (`num_authors`, `num_institutions`, `num_countries`)
  These provide high-level information about the scale and diversity of collaboration. Although their coefficients were smaller, they showed moderate group performance and strong generalizability.

- *Country Binaries*
  This group (e.g., `country_United States`, `country_China`) achieved a high standalone accuracy of 0.834. Countries often capture systemic research differences and were shown to generalize well.

- *Top 10 Author Binary Features*
  Rather than retaining all 100+ `author_` features, I selected only the 10 authors with the strongest and most stable coefficients. These included individuals like `author_Joachim Boldt` and `author_Diederik A Stapel`, who are known for repeated retractions. This balances interpretability, precision, and generalizability while reducing overfitting risk.
- *Year*
  The publication year exhibited a strong and stable negative coefficient (mean = -1.695, t-like score = -33.4), indicating that older papers are more likely to be retracted. While this makes intuitive sense—retractions take time—it also introduces the risk of temporal leakage. Year was therefore included for modeling purposes and interpretability, but its implications must be carefully considered (see discussion?).

==== Dropped Feature Groups

- *Author Binaries (except top 10)*
  The dataset originally included over 100 binary features indicating the presence of specific authors in a given paper. While a small subset of these features—such as those corresponding to known fraudsters like Joachim Boldt or Yoshitaka Fujii—exhibited strong and stable coefficients, the overall group achieved low predictive performance (mean accuracy of 0.546 when used alone). The main limitations of these features are twofold. First, their distribution is extremely sparse, with many authors occurring only once or twice. This encourages overfitting, as the model may learn to associate retractions with specific individuals rather than generalizable patterns. Second, reliance on known author identities hinders the model’s ability to flag retractions by previously unseen or future authors—an essential requirement for a robust detection system. For these reasons, only the ten most influential authors (based on mean coefficient magnitude and t-like score) were retained. All remaining author-level features were excluded to reduce dimensionality and mitigate overfitting.
  
- *Institution Binaries*
  Institution-level features were initially included as over 50 binary indicators for the most common affiliations. However, this feature group performed the worst in standalone evaluations, with a mean accuracy of just 0.525. Most institutions appeared only a few times in the dataset, making them statistically weak predictors. Additionally, institutional affiliation alone is not a consistent or reliable proxy for paper quality or retraction risk. In many cases, its influence is already captured by other features such as citation metrics. Including these sparse binary variables would increase model complexity and potentially reduce generalization to new or unseen data. As a result, all institution binaries were removed from the final logistic regression feature set.

- *Field and Domain Dummies*
  Although theoretically relevant, these features had limited predictive power in practice. When evaluated in isolation, the groups achieved a mean accuracy of only 0.553. Additionally, their broad categorization failed to capture the nuances between subfields, and their effect overlapped substantially with other features such as textual structure and semantic embeddings. Given their redundancy, low granularity, and weak model performance, all field and domain variables were excluded from the final feature set.


Final Feature Groups (Total: 167 features, including target retracted)


#table(
  columns: 3,
  align: left,
  [Group], [Count], [Notes],
  [Citation], [2], [`incoming_citations_count`, `outgoing_citations_count`],
  [Similarity], [4], [`mean_citation_context_to_cited_abstract_l2_-distance_y`, `mean_abstract_to_cited_abstract_l2_distance_y`, `max_-citation_context_to_cited_abstract_l2_distance_y`, `max_abstract_to_cited_abstract_l2_distance_y`],
  [Handcrafted Abstract], [30], [Features from abstract text, prefixed with `hc_`],
  [Handcrafted Fulltext], [30], [Full-text features, prefixed with `hc_ft_`],
  [Embeddings], [64], [Semantic vector features: columns `"0"` to `"63"`],
  [Meta Counts], [3], [`num_authors`, `num_institutions`, `num_countries`],
  [Country Binaries], [23], [One-hot encoded countries: `country_...`],
  [Top 10 Authors], [10], [Most impactful `author_...` binaries],
  [Year], [1], [Continuous year feature (standardized)],
  [Target], [1], [`retracted` (binary label)]
)


== 6.3 Significance Testing of Different Text Fields

To assess which textual components are most informative for predicting retractions, I conducted significance testing using a standard fine-tuned transformer model (`distilbert-base-uncased`) on three separate fields: `Abstract`, `FullText`, and `metadata_sentences`. The goal was to evaluate their individual predictive power with regard to the retraction label using consistent training and evaluation settings.

The model was fine-tuned on each field separately using 5 different random seeds to ensure robustness. Each training run used a stratified 80/20 train-test split, and evaluation was based on classification accuracy.

*Final Results*
#table(
  columns: 3,
  align: left,
  [Field], [Mean Accuracy], [Std Accuracy], [`metadata_sentences`], [1.0000], [0.0000], [`Abstract`],[0.9164], [0.0026], [`FullText `], [0.7526], [0.0011], 
)

*Interpretation of Results*

1. *`metadata_sentences` (Accuracy = 1.0000)* ???
   This result is unexpectedly perfect — the model achieved 100% accuracy with 0 variance across seeds. Upon manual inspection of the field, it became evident that `metadata_sentences` contains only descriptive information such as the country, institution, date, and scientific domain. It does not include any direct reference to retraction status, misconduct, or results.
   This suggests that the model is likely relying on *strong correlations between metadata and the label*, for example, certain countries or institutions being overrepresented in the retracted subset. While technically effective in this dataset, this result is misleading and likely reflects *label leakage* through non-generalizable metadata. Thus, this field should be excluded from text-based fraud detection tasks or analyzed separately as a metadata-based approach.

   
📄 Sample 2857
Label: NOT RETRACTED
Metadata Sentences:
This paper was written on 01/21/2021 00:00 in Germany, at German Center for Diabetes Research (DZD), Neuherberg, Germany;Institute of Diabetes Research and Metabolic Diseases (IDM), the Helmholtz Center, Munich, Germany, in the domain of Health Sciences, covering the field of Medicine.

📄 Sample 4398
Label: RETRACTED
Metadata Sentences:
This paper was written on 3/25/2021 0:00 in India, at Department of Computer Science & Engineering, Sri Krishna College of Technology, Kovaipudur, Coimbatore, Tamil Nadu, India, in the domain of Physical Sciences, covering the field of Computer Science.

📄 Sample 8280
Label: RETRACTED
Metadata Sentences:
This paper was written on 2/20/2019 0:00 in China, at Department of Traditional Chinese and Western Oncology, the First Affiliated Hospital of Anhui Medical University, No 120 Wanshui Road, High-tech Zone, Hefei 230088, Anhui, China;, in the domain of Life Sciences, covering the field of Biochemistry, Genetics and Molecular Biology.

📄 Sample 8995
Label: RETRACTED
Metadata Sentences:
This paper was written on 7/2/2022 0:00 in China, at Constrution Project Office of Wuchang Lalin River Section of Tieke Expressway, Harbin, Heilongjiang 150001, China;, in the domain of Physical Sciences, covering the field of Engineering.

📄 Sample 9689
Label: RETRACTED
Metadata Sentences:
This paper was written on 11/11/2021 0:00 in China, at Second Department of Spleen and Stomach Diseases, Gansu Provincial Hospital of Traditional Chinese Medicine, Lanzhou City 730050, Gansu, China; Department of Anorectal Diseases, Gansu Provincial Hospital of Traditional Chinese Medicine, Lanzhou City 730050, China;, in the domain of Health Sciences, covering the field of Medicine.

📄 Sample 1035
Label: NOT RETRACTED
Metadata Sentences:
This paper was written on 07/12/2019 00:00 in United States, at Howard Hughes Medical Institute Research Laboratory, Seattle, USA;Basic Sciences Division, Fred Hutchinson Cancer Research Center, 1100 Fairview Ave N, Seattle, WA, 98109, USA;Scientific Computing, Fred Hutchinson Cancer Research Center, 1100 Fairview Ave N, Seattle, WA, 98109, USA, in the domain of Life Sciences, covering the field of Biochemistry, Genetics and Molecular Biology.

📄 Sample 11588
Label: NOT RETRACTED
Metadata Sentences:
This paper was written on 09/08/2012 00:00 in United States, at Broad Institute of Harvard and Massachusetts Institute of Technology , Cambridge, Massachusetts 02142;Department of Genetics , Harvard Medical School, Boston, Massachusetts 02115;Affymetrix , Inc., Santa Clara, California 95051, in the domain of Physical Sciences, covering the field of Earth and Planetary Sciences.

📄 Sample 7099
Label: NOT RETRACTED
Metadata Sentences:
This paper was written on 06/27/2012 00:00 in China;United States, at 1 Division of Biostatistics, Dan L. Duncan Cancer Center and 2Department of Molecular and Cellular Biology, Baylor College of Medicine, Houston, TX 77030, USA and 3State Key Laboratory of Bioelectronics, School of Biological Science and Medical Engineering, Southeast University, Nanjing, China, in the domain of Life Sciences, covering the field of Biochemistry, Genetics and Molecular Biology.

📄 Sample 10250
Label: NOT RETRACTED
Metadata Sentences:
This paper was written on 01/01/2021 00:00 in China, at School of Computer Science and Engineering, Sun Yat-sen University, China, in the domain of Physical Sciences, covering the field of Computer Science.

📄 Sample 1356
Label: RETRACTED
Metadata Sentences:
This paper was written on 4/4/2012 0:00 in United Kingdom, at Wolfson Institute for Biomedical Research; MRC Laboratory for Molecular Cell Biology and Department of Neuroscience, Physiology and Pharmacology University College London, London WC1E 6BT, UK;, in the domain of Life Sciences, covering the field of Biochemistry, Genetics and Molecular Biology.


2. *`Abstract` (Accuracy = 91.6%)*
   The abstract field achieved high accuracy with low variance, making it the most reliable textual field for retraction prediction. This suggests that abstracts often contain subtle linguistic or content-based cues related to the quality or credibility of the paper. Unlike `metadata_sentences`, the abstract reflects the scientific reasoning and findings of the authors and is less likely to introduce unwanted biases. For this reason, the abstract was used as the primary text input for the deep learning approach in subsequent experiments.

3. *`FullText` (Accuracy = 75.3%)*
   The full-text field performed significantly worse than the abstract, despite theoretically containing more information. Several factors likely contributed to this: (1) longer texts were truncated to 256 tokens, potentially cutting off important information; (2) full texts are more variable in structure and may contain large sections unrelated to the scientific core (e.g., boilerplate methods or acknowledgements); and (3) there may be more noise and formatting inconsistencies. These results suggest that using the full text without further preprocessing (e.g., section extraction or summarization) is suboptimal in this context.

*Conclusion*

These findings highlight that not all text fields are equally informative for fraud detection. While metadata fields may allow near-perfect prediction within the current dataset, such results are likely driven by bias and label leakage. In contrast, abstracts strike a strong balance between informativeness and generalizability, making them a reliable input for building robust and explainable models.








