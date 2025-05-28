= Implementation
== Approach 1 – Logistic Regression


=== Initial Text-Based Model Evaluation
As a first step, I tested how well a purely text-based approach could predict scientific retractions. For this initial experiment, I compared two types of text representations, TF-IDF and sentence embeddings, across three standard classifiers: Logistic Regression, Random Forest, and XGBoost.

The goal was to identify which combination works best with my dataset and could serve as a solid baseline for further experiments. The results are shown below:

Among all tested combinations, Logistic Regression with TF-IDF achieved the highest and most stable accuracy. Based on these findings, I decided to continue with this setup for the next stages of my project. It provided a reliable baseline and allowed for interpretable analysis of feature importance in later steps.

#image("logreg.png")

== Baseline Model Evaluation Using TF-IDF and Logistic Regression
To establish a strong and interpretable baseline for the classification of retracted scientific publications, I conducted a series of controlled experiments using logistic regression with 5-fold stratified cross-validation. The goal was to compare the effectiveness of text-based features (TF-IDF) alone and in combination with additional structured features, such as handcrafted linguistic statistics, citation metrics, semantic similarity scores, and metadata.

=== Text Representations
Two different textual inputs were tested using TF-IDF vectorization:
- Abstract only: The most concise, curated section of the paper.
- FullText: A concatenation of the Abstract, Introduction, Methods, Conclusion, and Results & Discussion.

TF-IDF was applied using 1–2 n-grams and a vocabulary limited to the top 5,000 features. This ensures computational efficiency and helps reduce overfitting. This balances between:
- capturing sufficient lexical information,
- avoiding overly sparse or noisy features,
- and maintaining computational feasibility in combination with all numeric features.

=== Structured Features
In addition to the TF-IDF representations, I included the various numerical features I decided to retain:
- Handcrafted Features (Abstract / FullText): 30 linguistic and structural features per text section (e.g., sentence length, lexical density, stopword ratio).
- Citation and Semantic Similarity Metrics: Quantifying citation count and the semantic coherence between citing and cited texts.
- Embeddings: 64 precomputed sentence-level embeddings representing the paper’s semantic content.
- Metadata: Author count, institution count, country indicators, top retracted authors, and publication year (standardized).

=== Model and Evaluation
All experiments were conducted using logistic regression with L2 regularization (penalty='l2') and class_weight="balanced" to account for class imbalance. Model performance was evaluated with accuracy and ROC AUC, averaged across 5 folds.

Results Overview
Experiment	Accuracy	ROC AUC
TF-IDF Abstract only	0.9076	0.9665
TF-IDF FullText only	0.9139	0.9691
TF-IDF Abstract + All Numeric	0.9833	0.9984
TF-IDF FullText + All Numeric	0.9847	0.9984

=== Interpretation (andere section?)
Text alone performs very well, especially when using the full textual content. This suggests that linguistic patterns and vocabulary are strong indicators of retraction.

Adding structured numeric features significantly boosts performance, with both accuracy and ROC AUC approaching 99.8%.

The slight edge for FullText + All Features may be due to richer lexical variety, though it also introduces more noise.

These results indicate that a simple linear model, when supplied with well-engineered features, can perform remarkably well on this task.

== Hyperparameter Tuning with Optuna and Weights & Biases
After identifying the best-performing feature configuration — TF-IDF (FullText) + all numeric features — based on initial cross-validation experiments (Accuracy: 0.9847, ROC AUC: 0.9984), I conducted hyperparameter tuning to further optimize the logistic regression model. The goal was to fine-tune the model’s regularization and improve generalization, especially given the high dimensionality of the feature space.


=== Tuning Configuration
I used Optuna for efficient and automated hyperparameter search, combined with Weights & Biases (wandb) to log and visualize all runs. Each trial trained a logistic regression model using 5-fold stratified cross-validation to ensure robust evaluation across the dataset.

The following hyperparameters were tuned:

- C (Inverse Regularization Strength)	log-uniform between 1e-3 and 10.0	Controls L2 regularization strength; smaller values encourage stronger regularization and reduce overfitting.
- penalty	"l2" (fixed)	L2 regularization was chosen for stability with many correlated features; lbfgs solver supports this efficiently.

The solver was fixed to "lbfgs" as it supports L2 regularization and scales well for sparse, high-dimensional input like TF-IDF matrices.

Each Optuna trial was logged to Weights & Biases.

=== Outcome
After evaluating 30 different logistic regression configurations on the best-performing feature setup (TF-IDF on FullText + all numeric features), the optimal hyperparameters were:

- C = 9.52 (lower regularization strength → more flexible model)
- penalty = 'l2' (standard ridge penalty)

This configuration achieved a mean ROC AUC of 0.9989, slightly outperforming the original default (C = 1.0) setup, which had an AUC of 0.9984. The improvement, while small, confirms that the model benefits from reduced regularization when given a rich and highly informative feature set.

These hyperparameters will now be used for final training and evaluation (& test set?).



== Approach 2 – Deep Learning

To complement the simple, feature-based models used in the first approach, I explored a second approach based entirely on deep learning. The idea was to use transformer-based models that can directly learn patterns from the text of scientific publications without any handcrafted features. This method requires more computation, but it has the potential to capture complex language patterns and hidden relationships that classical models might miss.

=== Model Setup
All models were trained using the Hugging Face transformers library in combination with the Trainer API and Weights & Biases (wandb) for logging. For cross-validation, I used 3-fold stratified splits to make the training manageable within Google Colab's memory and runtime limits. The models were evaluated on both abstracts and full texts. However, since the abstract usually led to better performance and was more efficient to process, the reported results here focus on the Abstract input.

Key parameters used in the experiments:
- Number of folds: 3
- Epochs: 5
- Batch size: 8

Optimizer settings and early stopping were consistent across all models. Evaluation metrics: Accuracy, ROC AUC, Precision, Recall, and F1

The models I tested included:
- DistilBERT (distilbert-base-uncased)
- SciBERT (allenai/scibert_scivocab_uncased)
- PubMedBERT (microsoft/BiomedNLP-PubMedBERT-base-uncased-abstract-fulltext) (?)
- Longformer (allenai/longformer-base-4096)
- SciDeBERTa (KISTI-AI/Scideberta-full)

==== Token Limit and Input Length Handling
Transformer models have a maximum number of tokens they can process per input, which depends on the specific architecture. In this project, I used a dynamic setting for the max_length parameter based on the model type.

For most models such as SciBERT, PubMedBERT, DistilBERT, and SciDeBERTa, the maximum sequence length was set to 512 tokens, which is the standard for BERT-style models. These models are optimized for shorter input sequences and automatically truncate longer texts during tokenization.

For Longformer, which is specifically designed to handle longer documents, I set the maximum length to 4096 tokens. This allowed the model to process much larger portions of the text, which is useful for scientific papers with extensive content.

Because many full-text inputs exceeded 512 tokens, the majority of models trained on full-text data had to discard parts of the input. This may explain why models trained on abstracts often performed better — abstracts are concise, well-structured summaries that typically fit within the 512-token limit and still carry meaningful signals for classification.

=== Evaluation Results
Below are the average metrics across 3 folds for each model when trained on the Abstract field:

#table(
  columns: 6,
  align: left,
  [Model], [Accuracy], [ROC AUC], [Precision], [Recall], [F1 Score],
  [SciBERT], [0.9379], [0.9815], [0.9484], [0.9263], [0.9372],
  [PubMedBERT], [0.9363], [0.9833], [0.9587], [0.9121], [0.9348],
  [DistilBERT], [0.9243], [0.9753], [0.9324], [0.9154], [0.9236],
  [Longformer], [0.9266], [0.9778], [0.9399], [0.9122], [0.9255],
  [SciDeBERTa], [0.9324], [0.9817], [0.9499], [0.9137], [0.9311],
)


=== Analysis and Best Model Selection
All models performed very well, with ROC AUC scores above 0.97. Among them, PubMedBERT showed the highest ROC AUC (0.9833) and very strong precision (0.9587), making it a strong candidate. However, SciBERT delivered the most balanced performance overall with the highest accuracy (0.9379) and the best trade-off between precision and recall, resulting in the best F1 score (0.9372).

After comparing all results, I chose SciBERT as the best-performing model. It consistently achieved strong metrics across all folds and had the lowest evaluation loss among the top models. For this reason, I selected SciBERT for further hyperparameter tuning and final evaluation.

This deep learning approach shows that even when using only the abstract section, transformer models can detect retracted papers with very high performance. Compared to the logistic regression baseline, the improvement was small but still noticeable, especially in terms of F1 score and recall. This suggests that the model is better at picking up subtle linguistic indicators of retraction.

== Hyperparameter Tuning for SciBERT
After identifying SciBERT as the best-performing model during the initial deep learning experiments, I conducted a focused hyperparameter tuning step to improve its performance even further. The goal was to fine-tune key parameters in order to maximize the ROC AUC score and ensure good generalization to unseen data.

I used the Hugging Face Trainer interface together with Optuna, a powerful hyperparameter optimization framework. The tuning process was run on one representative fold of the training data to reduce runtime while still ensuring meaningful evaluation. I kept most training parameters fixed and only searched over two of the most relevant ones:

- Learning rate: searched between 1e-6 and 5e-5 on a log scale
- Weight decay: searched between 0.0 and 0.3

The tuning was done over 10 trials, and each trial trained a SciBERT model with a different combination of learning rate and weight decay. All other settings, such as the number of epochs (5), batch size (8), and maximum input length (512 tokens), were kept constant.

All trials were tracked using Weights & Biases (wandb) to allow for easy comparison and visualization of results.

At the end of the tuning, the best-performing configuration was selected based on the highest ROC AUC score. This configuration was then saved and later used for final model training and evaluation on the test set.

After completing the hyperparameter tuning for SciBERT, I retrained the model using the best configuration found during the search. This included the following parameters:

Model: allenai/scibert_scivocab_uncased
- Learning rate: 1.63e-5
- Weight decay: 0.263
- Epochs: 5
- Batch size: 8
- Max token length: 512
- Text input: Abstract

The model was trained on the full training data using a single train-validation split and evaluated after each epoch. 

The best performance was achieved during epoch 3, with an ROC AUC of 0.9840, an accuracy of 94.26%, and an F1 score of 0.9426. These results confirm that SciBERT, when fine-tuned on abstract-only input with optimized parameters, is highly effective at identifying retracted scientific papers.

To do: 
- Explain why ROC is best measurement?
- explain why fulltext performed worse? 