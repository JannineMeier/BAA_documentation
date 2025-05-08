#import "/template/_helpers.typ": todo

= Data Sources and Preprocessing

== Description of Data Sources

As the foundation for this project, I adopted and extended the dataset introduced in the paper *"Analyzing the Evolution of Scientific Misconduct based on the Language of Retracted Papers"*. The authors of this paper created a structured corpus by combining two primary sources: (1) *Retraction Watch*, which offers detailed records on retracted scientific articles including retraction reasons, and (2) *OpenAlex*, which provides a large-scale, open-access repository of scholarly metadata, including abstracts, citation data, authorship, affiliations, and field classification.

The original dataset was constructed by merging Retraction Watch entries with corresponding OpenAlex metadata, resulting in \~30k unique retracted articles, of which \~19k had usable abstracts. The full texts were partially supplemented through PDF downloads, and content sections like Introduction, Methods, Results & Discussion, and Conclusion were extracted via regex-based heuristics.

I adopted this dataset structure and used it as the basis for my own data pipeline. From the initial dataset, I focused solely on papers with available *abstracts*, ensuring a consistent text base for my experiments. I additionally extracted and retained metadata fields for each paper, including:

- `Field`, `Country`, and `Domain`: Broad categorization of the research.
- `OriginalPaperDOI` and `OriginalPaperDate`: Identifiers and timestamps.
- `Author`, `Institution`, `Language`: Contextual and attributional data.
- `Abstract`, `Introduction`, `Methods`, `Related Work`, `Result & Discussion`, `Conclusion`: Content-rich sections used for feature extraction.
- `retracted`: Label indicating whether the paper has been retracted.

To establish a binary classification task, I selected only papers with a complete abstract and labeled them as either retracted due to scientific *fraud* or *non-retracted*.

== Retraction Reason Selection and Labeling

The Retraction Watch database includes over 100 distinct retraction reasons, with each paper potentially associated with multiple labels. For this project, I manually defined a subset of retraction reasons indicative of *scientific fraud* and grouped them into the following categories:

- *1. Scientific Fraud*

- *1.1 Manipulation of the Publication Process* (7651 unique)

  - *Fake Peer Review* (4699)
  - *Paper Mill* (3503)
  - *Rogue Editor* (1972)

- *1.2 Scientific Misconduct by Authors* (4707 unique)

  - *Misconduct by Author* (1278)
  - *Falsification/Fabrication of Results* (71)
  - *Falsification/Fabrication of Data* (945)
  - *Randomly Generated Content* (3090)

- *2. High-Risk Author* *(included only in GNN approach)*

  - *Investigation by Journal/Publisher* (11440)
  - *Investigation by Third Party* (6707)
  - *Investigation by Company/Institution* (2001)
  - *Investigation by ORI* (190)
  - *Author Unresponsive* (75)
  - *Complaints about Author* (1209)

Due to significant overlap between these categories (particularly “Paper Mill” and “Randomly Generated Content”), I merged them into a single binary label: *scientific fraud* (retracted due to misconduct) vs. *non-retracted*. This enabled a focused and well-defined classification objective for all subsequent modeling.

== Dataset Merging and Cleaning

To build a robust and balanced dataset, I filtered the original retraction corpus to retain only papers with a non-empty abstract. After filtering, I obtained approximately *10,000 retracted papers* that met my criteria.

To create a comparable non-retracted sample, I drew articles from OpenAlex’s *most-cited publications* across various domains. The idea was to match the topical and temporal distribution of retracted papers while minimizing the risk of including soon-to-be-retracted or suspicious articles. I downsampled this reference set to obtain *approximately 10,000 non-retracted papers*, although I still need to double-check the precise sampling strategy that was applied.

== Feature Extraction and Engineering

Depending on the modeling approach, I extracted and engineered a range of features from both text and metadata. These included:

=== Text-Based Features

- *TF-IDF Vectors*: Created from the `Abstract` section to represent term frequency patterns.
- *Sentence Embeddings*: Derived using pre-trained transformer models (e.g., DeBERTa) to capture semantic structure and meaning. (?)

=== Handcrafted Features

- Features capturing stylistic cues (e.g., average sentence length, lexical diversity, number of digits or special characters).
- Section-specific properties (e.g., number of words in Conclusion vs. Methods).

=== Metadata Features

- Author-related: number of authors, affiliations, corresponding author country.
- Article-related: publication year, field/domain, institution type.
- Language and country distribution.

=== Network-Based Features

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

To maintain performance and data integrity, the crawler employed asynchronous requests (`aiohttp`, `asyncio`) with a semaphore-based rate limiter and checkpointed partial results to a compressed `.parquet` file. This allowed for incremental data collection, resilience to interruptions, and efficient recovery across large-scale runs.

The enriched metadata was later used to compute network-based features such as in-degree, out-degree, and PageRank, as well as to construct semantic profiles of authors and citation neighborhoods. These features played a vital role in powering the graph-based models, particularly in the Graph Neural Network (GNN) framework.

Perfect! Here’s the full, **English version** of your expanded section, cleanly structured and **ready to paste into your Typst thesis**:

== Computed Citation Statistics

From the enriched citation metadata, I derived two additional numeric features representing local network structure:

The first feature, incoming_citations_count, represents the number of other papers that cite a given paper—this is equivalent to the paper's in-degree in the directed citation graph.

The second feature, outgoing_citations_count, indicates how many references the paper includes, corresponding to its out-degree.

Both values were derived by counting the number of entries in the incoming_citations and outgoing_citations lists, respectively.

These were calculated by counting the number of entries in the fields `incoming_citations` and `outgoing_citations`, respectively. They provide important indicators of a paper’s position and connectivity in the citation network and are used both for exploratory data analysis and as input features in downstream models.


== Node Embeddings for the Citation Network

To incorporate structural information from the citation network into my models, I generated **node embeddings** using the directed citation graph constructed from paper-to-paper references.

Each node in the graph corresponds to a paper (identified by its DOI), and each directed edge represents a citation from one paper to another.

The embedding pipeline followed these steps:

1. **Graph Construction**
   A directed graph was built using the `networkx.DiGraph` class. Each node corresponds to a paper DOI, and directed edges were added from the citing paper to each of its cited papers. Invalid entries (e.g., malformed DOIs) were filtered out during construction.

2. **Embedding Model Selection**
   I used **ProNE**, a scalable and fast graph embedding model well-suited for large graphs. It was configured with 64-dimensional output vectors and trained on the full graph. Optionally, GGVec was considered as an alternative embedding algorithm, offering a good trade-off between quality and speed.

3. **Embedding Training**
   The model was trained directly on the citation graph to learn low-dimensional vector representations for each paper, capturing both structural and topological relationships.

4. **Embedding Extraction and Storage**
   After training, embeddings were extracted and filtered to include only papers present in the modeling dataset. The final node embeddings were stored in `.pkl` format, and the trained model was also saved for reproducibility.

These embeddings served as input features for models requiring a dense, vectorized representation of each paper's position in the citation network, such as GNN-based classifiers and hybrid ML pipelines.

Absolutely! Here's a version of the two sections rewritten in a more **student-like tone**, using clear and natural language without dashes or overly formal phrasing — perfect for Typst and easier to read:

== Metadata Thresholding for Rare Categories

In my dataset, columns like `Country`, `Institution`, `Domain`, and `Field` had many different values. Some of these values only showed up a few times, which made it hard for models to learn anything useful from them. For example, if one university only appeared in two papers, it would not provide a strong learning signal and could even lead to overfitting.

To solve this, I decided to apply a threshold. I grouped all values that appeared *less than 50 times* under a general category called *"other"*. I chose the value of 50 after trying different settings and looking at the data. A lower threshold didn’t reduce the noise enough, and a higher one removed too much useful detail. So 50 was a good balance between keeping important information and removing rare, noisy values.

For each of the affected columns, I created a new version with the suffix `_threshold`. For example, `Country_threshold` contains either the original country name or "other", depending on how often the country appears in the dataset. I applied this process to the following columns:

- `Country`
- `Institution`
- `Domain`
- `Field`

This step helped simplify the metadata and made it easier for the models to focus on patterns that appear more often in the data.

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
