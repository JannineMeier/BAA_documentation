#import "/template/_helpers.typ": todo
#import "/template/_helpers.typ": title-caption
#import "@preview/acrostiche:0.5.0": acr, acrfull

= Data Sources and Preprocessing

== Description of Data Sources

As the foundation for this thesis, I adopted and extended the dataset from the structured corpus developed in *Analyzing the Evolution of Scientific Misconduct based on the Language of Retracted Papers"* @blessetal.AnalyzingEvolutionScientific2025. The original corpus integrates two critical data sources:

1. *Retraction Watch*: A comprehensive database tracking retracted scientific articles, including detailed retraction reasons.

2. *OpenAlex*: An open-access repository of scholarly metadata, providing abstracts, citations, authorship, affiliations, and field classifications.

By combining these sources, #cite(<blessetal.AnalyzingEvolutionScientific2025>, form: "prose") enabled systematic analysis of linguistic patterns in retracted papers, which this project further expands.

The original dataset was constructed by merging Retraction Watch entries with corresponding OpenAlex metadata, resulting in \~30k unique retracted articles, of which \~19k had usable abstracts. Content-rich sections such as Introduction, Methods, and Conclusion were already extracted in the original dataset. These were identified using regular expression-based heuristics applied to the full text and labeled accordingly. I reused these pre-labeled sections without modifying the paragraph segmentation, and focused primarily on the Abstract for my core experiments.

I adopted this dataset structure and used it as the basis for my own data pipeline. From the initial dataset, I focused solely on papers with available *abstracts*, ensuring a consistent text base for my experiments. I additionally extracted and retained metadata fields for each paper. Many metadata fields (e.g., Author, Institution, Country) were stored as semicolon-separated strings containing multiple entries per paper. Metadata fields include:

- `Field`, `Country`, and `Domain`: Broad categorization of the research.
- `OriginalPaperDOI` and `OriginalPaperDate`: Identifiers and timestamps.
- `Author`, `Institution`, `Language`: Contextual and attributional data.
- `Abstract`, `Introduction`, `Methods`, `Related Work`, `Result & Discussion`, `Conclusion`: Content-rich sections used for further feature extraction.
- `retracted`: Label indicating whether the paper has been retracted.

Many metadata fields (e.g., Author, Institution, Country) were stored as semicolon-separated strings containing multiple entries per paper. 

To establish a binary classification task, I selected only papers with a complete abstract and labeled them as either retracted due to scientific *fraud* or *non-retracted*. The binary classification label (scientific fraud vs. non-retracted) was created based on a curated subset of Retraction Watch categories, as detailed in @labeling. Abstracts were selected as the core text input due to their concise summarization of a paper’s content, near-universal availability, and reduced risk of structural noise compared to full texts. 

== Retraction Reason Selection and Labeling <labeling>

The Retraction Watch database includes over 100 distinct retraction reasons, with each paper potentially associated with multiple labels. For this project, I manually defined a subset of retraction reasons indicative of *scientific fraud* and grouped them into the following categories. I chose these categories because they clearly involve intentional deception, manipulation, or serious misconduct. This sets them apart from cases that might just involve mistakes (like data loss or plagiarism) or procedural problems (like disputes about authorship). The goal was to focus specifically on types of fraud that seriously threaten the integrity of scientific research.

#set list(
  marker: [•],
  indent: 1.5em,
  spacing: 0.6em
)

#list(
  [*Scientific Fraud*],
  list(
    [_Manipulation of the Publication Process_ (7,651 unique)],
    list(
      [Fake Peer Review (4,699)],
      [Paper Mill (3,503)],
      [Rogue Editor (1,972)],
    ),
    [_Scientific Misconduct by Authors_ (4,707 unique)],
    list(
      [Misconduct by Author (1,278)],
      [Falsification/Fabrication of Results (71)],
      [Falsification/Fabrication of Data (945)],
      [Randomly Generated Content (3,090)],
    ),
  ),
  
  [*High-Risk Author* (used only for GNN features)],
  list(
    [Investigation by Journal/Publisher (11,440)],
    [Investigation by Third Party (6,707)],
    [Investigation by Company/Institution (2,001)],
    [Investigation by ORI (190)],
    [Author Unresponsive (75)],
    [Complaints about Author (1,209)],
  )
)

Due to significant overlap between these categories as seen in @labeloverlaps (particularly “Paper Mill” and “Randomly Generated Content”), I merged them into a single binary label: *scientific fraud* (retracted due to misconduct) vs. *non-retracted*. This enabled a focused and well-defined classification objective for all subsequent modeling. Note that many papers were associated with multiple retraction reasons; for binary labeling, papers matching at least one fraud-related reason were marked as scientific fraud. Papers with no fraud-related labels and no retraction were treated as non-retracte}.


#figure(
  image("/images/overlap splits.png", width: 50%),
  caption: title-caption(
    [Overlap Between Retraction Reason Categories],
    [Overlap Between Retraction Reason Categories in the Retraction Watch Database],
  )
)<labeloverlaps>

continue hereeee


== Dataset Merging and Cleaning

To build a robust and balanced dataset, I filtered the original retraction corpus to retain only papers with a non-empty abstract. After filtering, I obtained approximately *10,000 retracted papers* that met my criteria.

To create a comparable non-retracted sample, I drew articles from OpenAlex’s *most-cited publications* across various domains. The idea was to match the topical and temporal distribution of retracted papers while minimizing the risk of including soon-to-be-retracted or suspicious articles. 

I randomly downsampled this reference set to obtain *approximately 10,000 non-retracted papers*.


== Feature Extraction and Engineering

Depending on the modeling approach, I extracted and engineered a range of features from both text and metadata. 

=== Dropped Features from Original Dataset

I decided to drop the Language column because almost all the papers are written in English (over 99%). There are only a few entries in other languages, like German or French, which isn't enough to be useful for training a model. Keeping this feature would just add unnecessary noise, so I removed it to keep things cleaner and more focused.

=== Adjusted Features from Original Dataset
In the course of preparing the dataset for model training, I paid particular attention to the metadata fields Author, Institution, and Country. These fields originally consisted of semicolon-separated strings, often containing multiple entries per paper. For example, a single entry in the Author column could list several names as "Derek C. Angus;Tom van der Poll", or the Country field might combine "Netherlands;United States". While this format is human-readable, it is not suitable for use in machine learning models—especially not for linear models like logistic regression that rely on clearly defined, numerical input features.

The main issue with these fields in their original format is that they are both unordered and highly variable in length. The order in which authors or institutions appear does not carry meaningful information, and treating the entire string as a categorical variable would result in an excessive number of unique, sparsely repeated combinations. Moreover, standard encoding techniques like one-hot encoding or label encoding are ill-suited for such long-tail, high-cardinality text data. Therefore, in order to extract useful signal from these metadata fields while keeping the dataset interpretable and model-friendly, I decided to transform them into structured, count-based, and frequency-aware features.

I began by calculating the number of authors, institutions, and countries listed per paper. These new features (num_authors, num_institutions, and num_countries) serve as simple but informative indicators of collaboration scope or international involvement. In particular, I assumed that the number of authors or contributing institutions might correlate with factors like research quality or interdisciplinary character, which could in turn influence the likelihood of retraction.

Beyond the counts, I also wanted to capture information about the presence of specific authors, institutions, or countries—especially those that appear frequently across the dataset. To achieve this, I identified the most common entries in each category: the top 100 authors, the top 50 institutions, and the top 20 countries. For each of these, I created binary indicator features that denote whether the corresponding entity is involved in a given paper. This approach allows the model to learn patterns related to well-known or prolific contributors without relying on raw textual identifiers.

Given the long tail of rare or unique entries, I also introduced an “Other” category in each group to flag cases where none of the top entries were present. This ensures that all papers are represented within the new feature set, even if they involve lesser-known authors or institutions.

Overall, this feature engineering step helped convert raw metadata into meaningful, structured inputs that can be interpreted by models and potentially linked to retraction risk. It also ensures better generalizability and avoids the overfitting risks associated with high-cardinality categorical text.


=== Text-Based Features

- *TF-IDF Vectors*: Created from the `Abstract` section to represent term frequency patterns.
- *Sentence Embeddings*: Derived using pre-trained transformer models (e.g., DeBERTa) to capture semantic structure and meaning. (?)

=== Handcrafted Text-Based Features

In addition to embeddings and metadata, I created a large set of handcrafted features to capture different characteristics of the text in a more interpretable way. These features were designed to reflect writing style, structure, and linguistic patterns that could help distinguish between retracted and non-retracted papers.

The features were extracted from two main text sources:
- *the abstract*
- *the full text*, which I generated by concatenating the sections Introduction, Related Work, Methods, Result&Discussion, and Conclusion

To process the texts, I used tokenization from the nltk library and regular expressions for pattern matching. I also removed stopwords using the default English stopword list from nltk.

The handcrafted features included a total of 30 abstract-based features and 30 full-text-based features, each prefixed accordingly (hc_ for abstract, hc_ft_ for full text). 

Examples of the extracted features include:
- *Basic text statistics*
  Such as total number of characters (char_count), words (word_count), sentences (sentence_count), and average word or sentence length.

- *Linguistic ratios*
  Including stopword ratio, type-token ratio (TTR), uppercase ratio, digit ratio, and special character ratio.

- *Syntactic and stylistic markers*
  Like the number of passive-voice patterns, negations (e.g., “not”, “never”), modal verbs (e.g., “might”, “could”), and personal pronouns (“I”, “we”).

  *Lexical and punctuation features*
  Such as lexical density, number of questions, exclamations, quotes, commas, colons, semicolons, periods, and use of adverbs as a proxy for adjective or descriptive style.

- *Word length ratios*
  For example, the ratio of long words (more than 6 characters) and short words (3 characters or less).

All features were computed using custom Python functions with nltk and re, and stored in a pandas DataFrame. To make them usable for machine learning models, I applied standardization using StandardScaler from scikit-learn. This step ensures that all features are on the same scale, which is especially important when combining them with other numeric inputs like citation counts or similarity scores.

In total, each paper was represented by 60 handcrafted features: 30 from the abstract and 30 from the full text. These features were then saved into the final dataset for further analysis and model training.

=== Metadata Features (?)

- Author-related: number of authors, affiliations, corresponding author country.
- Article-related: publication year, field/domain, institution type.
- Language and country distribution.

=== Network-Based Features (?)

For my *GNN models*, I further enriched the dataset with *graph-based features*, including:

- *Citation Counts*: In-degree and out-degree from the citation graph.
- *Author Metrics*: Aggregated publication and citation counts per author.
- *Node Embeddings*: Using *Node2Vec* trained on the citation graph to capture structural relationships among papers.


== Additional Metadata Enrichment via OpenAlex API

To extend the initial dataset with more detailed structural and contextual information, I implemented a custom asynchronous crawler leveraging the [OpenAlex API](https://openalex.org/). This enrichment step was critical for supplying additional input features to my models — especially those relying on citation networks, authorship metadata, and paper connectivity.

In order to query OpenAlex at scale and avoid throttling issues, I registered and used a *personal API key*, which granted me higher rate limits and ensured reliable access to the required endpoints.

For each paper in the dataset (based on its DOI), the crawler retrieved:

- *Cited-by Count*: The number of papers citing the target article.
- *Outgoing Citations*: A list of DOIs representing all works the article references.
- *Incoming Citations*: A list of OpenAlex records (with IDs, DOIs, and titles) for all articles that cite the target paper. These were retrieved via paginated queries and merged to ensure full coverage.

In addition to paper-level information, I collected extensive *author-level metadata* for each listed contributor:

- *OpenAlex Author ID and ORCID* (if available),
- *Works Count and Citation Count* (overall and per year),
- *Institutional Affiliations* from both the specific authorship and the most recent known association,
- *Topical Embeddings* via `x_concepts`, including concept IDs, display names, and relevance scores.

The enriched metadata was later used to compute network-based features such as in-degree, out-degree. These features played a vital role in powering the graph-based models, particularly in the Graph Neural Network (GNN) framework.I initially included PageRank as a network feature to capture the relative importance of each paper based on citation links. However, the computed values were extremely small with no meaningful variation across nodes. The maximum and minimum values differed only at the 18th decimal place. This indicates that the citation graph was too sparse or poorly connected for PageRank to provide useful insights. Due to its lack of variance and interpretability, I decided to exclude the PageRank feature from further analysis.

The other author features had a lot of potential for model improvement. For example, the average citation activity of authors could help indicate their reputation, while the variety of research topics could hint at whether a paper was more specialized or broad. Similarly, institutional data could give insights into where retracted papers tend to come from.

However, I wasn’t able to fully integrate all of this author-level data into my models due to time constraints. Features like citation trends over time or topic diversity would have required more pre-processing and aggregation. Although I did manage to use some basic citation-based features like in-degree, out-degree for my graph-based model, the more detailed author metadata wasn’t included in the final training pipeline.

maybe in other section: Still, collecting this data was a useful step. It gave me a deeper understanding of what additional information could be useful for retraction prediction. Even though I didn’t use all of it in this version of the project, the enriched dataset is ready and could be used in future experiments to improve the results.



== Computed Citation Statistics

From the enriched citation metadata, I derived two additional numeric features representing local network structure:

The first feature, incoming_citations_count, represents the number of other papers that cite a given paper—this is equivalent to the paper's in-degree in the directed citation graph.

The second feature, outgoing_citations_count, indicates how many references the paper includes, corresponding to its out-degree.

Both values were derived by counting the number of entries in the incoming_citations and outgoing_citations lists, respectively.

These were calculated by counting the number of entries in the fields `incoming_citations` and `outgoing_citations`, respectively. They provide important indicators of a paper’s position and connectivity in the citation network and are used both for exploratory data analysis and as input features in downstream models.


== Node Embeddings for the Citation Network

To incorporate structural information from the citation network into my models, I generated *node embeddings* using the directed citation graph constructed from paper-to-paper references.

Each node in the graph corresponds to a paper (identified by its DOI), and each directed edge represents a citation from one paper to another.

The embedding pipeline followed these steps:

1. *Graph Construction*
   A directed graph was built using the `networkx.DiGraph` class. Each node corresponds to a paper DOI, and directed edges were added from the citing paper to each of its cited papers. Invalid entries (e.g., malformed DOIs) were filtered out during construction.

2. *Embedding Model Selection*
   I used ProNE, a scalable and fast graph embedding model well-suited for large graphs. It was configured with 64-dimensional output vectors and trained on the full graph. Optionally, GGVec was considered as an alternative embedding algorithm, offering a good trade-off between quality and speed.

3. *Embedding Training*
   The model was trained directly on the citation graph to learn low-dimensional vector representations for each paper, capturing both structural and topological relationships.

4. *Embedding Extraction and Storage*
   After training, embeddings were extracted and filtered to include only papers present in the modeling dataset. The final node embeddings were stored in `.pkl` format, and the trained model was also saved for reproducibility.

These embeddings served as input features for models requiring a dense, vectorized representation of each paper's position in the citation network, such as GNN-based classifiers and hybrid ML pipelines.

To explore the learned node embeddings, I applied t-SNE to reduce the 64-dimensional vectors to 2D. The resulting embeddings were visualized in scatterplots, colored by metadata attributes such as year, field, domain, and retraction status. This provided an intuitive overview of potential structure or clustering in the citation network.

#image("emb by year.png", width: 200pt)

#image("emb by field.png", width: 200pt)

#image("emb by domain.png", width: 200pt)

#image("emb by retraction.png")

== Metadata Thresholding & One-Hot Encoding for Rare Categories

In my dataset, columns like `Country`, `Institution`, `Author`, `Domain`, and `Field` had many different values. Some of these values only showed up a few times, which made it hard for models to learn anything useful from them. For example, if one university only appeared in two papers, it would not provide a strong learning signal and could even lead to overfitting.

To solve this, I decided to apply a threshold. I grouped all values that appeared *less than 50 times* under a general category called *"other"*. I chose the value of 50 after trying different settings and looking at the data. A lower threshold didn’t reduce the noise enough, and a higher one removed too much useful detail. So 50 was a good balance between keeping important information and removing rare, noisy values.

For `Domain`, and `Field`, I created a new version with the suffix `_threshold`. For example, `Domain_threshold` contains either the original domain name or "other", depending on how often the domain appears in the dataset. This step helped simplify the metadata and made it easier for the models to focus on patterns that appear more often in the data.

I discovered that the `Country`, `Institution` and `Author` fields in the original dataset were stored as free-form semicolon-separated strings of variable length—examples like “ETH Zurich; University of Geneva; CERN” or “Switzerland; France” meant each record could contain a completely different number of entries, which is incompatible with the fixed-length numeric input that machine-learning algorithms usually require. To resolve this, I converted every unique author, institution and country into its own binary column: after counting the frequency of each label, I selected the top 100 authors, top 50 institutions and top 20 countries and created a separate feature for each that takes the value one if that label appears in the record and zero otherwise, adding an additional “Other” feature to flag any labels outside those top groups. This one-hot, multi-label encoding transforms each variable-length list into a consistent, sparse numeric matrix that standard classifiers and regressors can process efficiently while keeping the overall feature space manageable and preserving the interpretability of each indicator.

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
*“This paper was written on 06/10/2021 00:00 in China;Australia, at School of Information and Communication Technology, Griffith University, Nathan, QLD, Australia;College of Computer and Information, Hohai University, Nanjing, China, in the domain of Physical Sciences, covering the field of Computer Science.”*

And here is an example of a sentence using the thresholded values:
*“This paper was written on 06/10/2021 00:00 in other, at other, in the domain of Physical Sciences, covering the field of Computer Science.”*

If some parts of the metadata were missing, I just left them out or replaced them with "other". The final sentences were saved in a column called `metadata_sentence_threshold`, so they could easily be added to the model input later.

This approach allowed me to give the models extra context without changing their architecture. It also made it possible to use metadata in the same way as the abstract or introduction — as text that the model could read and learn from.

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








