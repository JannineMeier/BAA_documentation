= Evaluation of Approaches

== Overview of all results (Accuracy, ROC AUC, etc.)

🧾 Computing TF-IDF on FullText...
📐 Preparing numeric features...
🤖 Fitting final model with best hyperparameters...

📊 Final Test Evaluation:
----------------------------
Accuracy:       0.9995
ROC AUC:        1.0
Confusion Matrix:
[[2100    1]
 [   1 2100]]

Classification Report:
              precision    recall  f1-score   support

           0       1.00      1.00      1.00      2101
           1       1.00      1.00      1.00      2101

    accuracy                           1.00      4202
   macro avg       1.00      1.00      1.00      4202
weighted avg       1.00      1.00      1.00      4202


Deep learning

After hyperparameter tuning and cross-validation, the SciBERT model (allenai/scibert_scivocab_uncased) was trained on the full training dataset using the best configuration found: a learning rate of 1.63e-5, weight decay of 0.263, batch size of 8, sequence length of 512, and 5 training epochs.

The trained model was then evaluated on the previously unseen test set, using only the abstracts as input text. The evaluation was performed using the Hugging Face Trainer API and included metrics relevant to binary classification. The results are as follows:

Loss: 0.4019

Accuracy: 93.88%

ROC AUC: 0.9826

Precision: 95.69%

Recall: 91.91%

F1 Score: 93.76%

These results confirm that the fine-tuned SciBERT model performed very well on the test set, achieving both high recall and high precision, which are especially important in the context of retraction detection. The ROC AUC score of 0.9826 also indicates excellent discriminative ability.

== Resultsss
To evaluate the impact of different feature configurations on retraction detection performance, four model setups were compared on the final test set:

Logistic Regression (All Features): Includes full text (TF-IDF), all handcrafted features, citation metrics, country indicators, author-level metadata, and year.

Logistic Regression (No Citation): Removes all citation-based features (incoming/outgoing counts, similarity metrics).

Logistic Regression (No Citation & No Country): Additionally removes country indicator features.

SciBERT (Abstract): Fine-tuned transformer model using only the abstract text without handcrafted or metadata features.

#image("results.png")

=== ?Interpretation
The logistic regression model using all available features performs almost perfectly across all metrics, suggesting that the combination of handcrafted features, citation data, and metadata (especially country and author indicators) is highly informative for retraction prediction.

However, such high performance raises the concern of overfitting to metadata patterns that may not generalize well to unseen or future datasets. In particular:

Citation counts can reflect post-retraction effects or community awareness and may leak label information.

Country indicators might capture dataset biases rather than meaningful scientific misconduct patterns.

Highly cited authors or specific institutional affiliations may dominate patterns in the training data but don’t necessarily indicate future retractions.

Highly cited authors or specific institutional affiliations may dominate patterns in the training data but don’t necessarily indicate future retractions.

Moreover, an important selection bias arises from the way the non-retracted (negative) examples were chosen in this study. To construct a balanced dataset, the non-retracted papers were sampled from the most cited scientific publications available. While this approach helps ensure comparability in terms of visibility, length, and metadata completeness, it also introduces a significant bias:

Highly cited papers tend to come from well-established authors, institutions, or countries, and are often published in high-impact journals.

These papers are also more likely to have undergone rigorous peer review and to be better written, both structurally and linguistically.

As a result, the model may have learned to associate certain writing styles, citation patterns, or metadata (e.g., prestigious affiliations) with non-retraction, simply because the negative class was skewed toward “elite” publications.

This has two consequences:

Overfitting to prestige indicators: The model may implicitly assume that well-cited, institutionally strong papers are less likely to be retracted — which is not a causally valid assumption and might fail in real-world scenarios where misconduct can happen anywhere.

Under-representation of “typical” non-retractions: In reality, the vast majority of non-retracted papers are not highly cited. This means the model might not generalize well to average papers with low visibility, especially from underrepresented fields, languages, or regions.

To address this, future iterations of the project should aim to:

Include a more representative sample of non-retracted papers, ideally covering the full spectrum of citation counts and journals.

Evaluate performance on real-world class distributions to detect over-reliance on citation-related features.

Possibly stratify non-retracted examples to reflect a diversity of publication types and sources.

By acknowledging this bias, we can better interpret the model’s results and avoid drawing overly optimistic conclusions about its robustness or fairness when applied beyond the scope of this controlled setup.

To test for these risks, the same model was retrained without citation features, and then again without both citation and country data. The performance remained impressively high in both cases, indicating that while citation-based features boost performance, they are not strictly necessary for accurate classification. Removing them slightly reduced precision and recall but still yielded near-perfect ROC AUC values (~0.9999), which confirms the strength of the remaining feature set.

Lastly, a fine-tuned SciBERT model using only abstract text was evaluated to test a deep learning approach without handcrafted or structured input. While it performed the weakest overall, it still achieved strong results (ROC AUC: 98.26%, F1 Score: 93.76%), especially given it relied solely on raw textual content. This shows the model was able to extract meaningful linguistic patterns from scientific writing alone.

== Strengths and weaknesses of each method
These experiments show that handcrafted features and metadata significantly boost performance — but can also introduce overfitting risks. Removing potentially leaky features (like citation or geopolitical data) allows for a more robust and generalizable model, especially if deployed across domains or over time. Meanwhile, transformer-based models like SciBERT offer a promising metadata-free alternative, especially in cases where only the raw paper text is available.

== Trade-offs: interpretability, performance, scalability

== Suitability for real-world deployment
Real-World Imbalance and the Need for Extreme Precision
It’s important to note that this project used a balanced dataset, where the number of retracted and non-retracted papers was equal. While this setup is helpful for training and benchmarking, it does not reflect the real-world distribution of retracted scientific papers. According to estimates, fewer than 0.1% of all publications are retracted — making this a highly imbalanced classification task in reality.

As a result, even a classifier with very high accuracy in a balanced test setting (e.g., 99%) might fail completely in the real world by generating a large number of false positives. For example:

If only 1 in 1,000 papers is retracted, then a model that incorrectly flags 1% of papers as retracted would trigger 10 false positives for every true positive.

This could severely harm reputations and trust in scientific communication if applied naively.

In such low-prevalence settings, precision becomes critical. A useful retraction detection model would need to maintain extremely high precision (ideally >99.9%) while minimizing false alarms. It also means such a model would likely need to operate in a human-in-the-loop setting, flagging only high-confidence cases for expert review.

To apply this model practically, future experiments should include:

Re-training on an imbalanced dataset that reflects the true class distribution,

Exploring threshold tuning to optimize for precision,

And considering calibration techniques to better reflect the real probability of retraction.

Ethical Considerations
While the results of this study demonstrate that retraction detection models can achieve very high accuracy in controlled settings, applying such tools in the real world raises important ethical concerns.

Most importantly, any automated model — regardless of its statistical performance — should not be used to make final decisions about the credibility or integrity of scientific research. Retraction is a serious and often reputationally damaging action. Therefore, such decisions must remain in the hands of qualified human experts, with transparent procedures and due process.

The role of a machine learning model in this context should be strictly limited to serving as a supportive flagging tool. Its purpose would be to assist editors, reviewers, or watchdog institutions by identifying papers that exhibit linguistic or structural anomalies, unusual metadata patterns, or citation behaviors that warrant further human review. This can help focus attention and resources on potential problem cases, but not replace judgment or formal investigation.

Using such a model without careful oversight risks:

False accusations against innocent researchers,

Bias reinforcement, if the model has learned from skewed or context-specific training data,

And misuse by institutions or publishers, especially if used for large-scale screening without transparency.

To avoid these risks, any deployment of retraction prediction models should adhere to strict ethical guidelines:

Use models only to suggest possible retractions, not confirm them.

Ensure human oversight in every decision-making loop.

Make model outputs explainable and interpretable.

Regularly audit the model for bias, drift, and unintended effects.

Be transparent about its limitations and data sources.

In short, while machine learning offers exciting opportunities to enhance research integrity, it must be handled with care, humility, and a deep respect for the real-world impact its predictions may have.
== Error Analysis (here?, opt.)


== Temporal Bias Evaluation

== Objective

To evaluate whether the performance of the logistic regression model is influenced by the publication year of scientific articles, we tested for the presence of *temporal bias* in the dataset. The aim was to investigate whether a model trained on papers from one time period generalizes poorly to papers from other periods. This is important because retracted publications may exhibit different patterns over time due to evolving scientific standards, language use, citation behavior, and metadata structure.

== Methodology

The dataset contains a `Year` column, which we used to define three targeted time-based splits:

#table(
  columns: 5,
  align: left,
  [Split Name], [Training Period], [Testing Period], [Description], [Label],
  [Recent → Old], [2019–2024], [Before 2019], [Train on recent papers], [A],
  [Old → Recent], [Before 2015], [2015–2024], [Train on early papers], [B],
  [2010+ → -2010], [2010–2024], [Before 2010], [Train on modern data], [C],
)


Each split was vectorized using TF-IDF on the combined `FullText`, then combined with numerical features including handcrafted features, semantic embeddings, citation statistics, metadata, and binarized author/institution indicators. Hyperparameter tuning was performed with Optuna, and final evaluations were based on accuracy, ROC AUC, confusion matrices, and class-wise precision, recall, and F1 scores.

== Results

#table(
  columns: 6,
  align: left,
  [Split], [Accuracy], [ROC AUC], [Recall (Class 1)], [Recall (Class 0)], [Interpretation],
  [A], [0.9015], [0.9980], [1.00], [0.84], [Overpredicts fraud in old data],
  [B], [0.8753], [0.9901], [0.78], [0.99], [Misses fraud in newer data],
  [C], [0.9782], [0.9975], [1.00], [0.96], [Strong generalization to older papers],
)

== Interpretation

*Split A:* The model trained on recent papers performs well overall, but shows reduced recall for class 0 (non-retracted papers) on older documents. This leads to a high false positive rate. The likely cause is that papers from earlier periods differ in structure, terminology, or metadata availability compared to recent ones. This indicates a *temporal bias toward newer writing styles*.

*Split B:* The model trained on older data struggles to detect retracted papers in newer years, as reflected by a significantly lower recall for class 1 (retracted papers). This suggests a potential *concept drift*, where the linguistic or structural features of fraudulent papers have changed over time.

*Split C:* Interestingly, this split demonstrates very strong performance despite testing on data from before 2010. This implies that the training data from 2010 onward already includes sufficient diversity to generalize well. However, the relatively small test set in this split may also contribute to this result and should be interpreted cautiously.

== Conclusion

These experiments confirm that the model exhibits *temporal sensitivity*, with significantly different performance depending on the training and testing periods. This underlines the importance of adopting *time-aware validation strategies*, explicitly modeling *temporal context*, or retraining models periodically in production settings to maintain robustness over time. Future work should explore the integration of temporal features and dynamic sampling methods to mitigate these effects.


== Discussion downsampling

What would be better maybe: Instead of randomly selecting non-retracted papers, I applied a more informed downsampling strategy. For each paper labeled as retracted, I looked at its Field, Domain, and year of publication (extracted from OriginalPaperDate). I then attempted to sample an equal number of non-retracted papers from the same (Field, Domain, Year) combinations. This helped ensure that the characteristics of the retained non-retracted papers were as close as possible to those of the retracted ones, reducing the risk of introducing unwanted bias from imbalanced distributions across disciplines or time periods.