= Conclusion

== Discussion
=== Interpretation of key results

=== Limitations of the data and models (ethical stuff?)
==== Year as a Predictive Feature: Strengths and Limitations

The publication year of a paper emerged as one of the most influential features in the logistic regression model, ranking among the top five predictors based on coefficient magnitude and statistical stability. This result highlights that temporal information holds meaningful signal in the context of retraction prediction. Several factors likely contribute to this effect. First, older publications have had more time to be retracted, introducing a natural correlation between age and retraction likelihood. Second, the scientific publishing landscape has evolved considerably over time—peer review procedures, editorial standards, and the mechanisms for detecting misconduct have all changed. Third, temporal trends may also reflect domain-specific shifts in research practices or heightened scrutiny in certain fields during particular periods.

Despite its statistical utility, the inclusion of Year as a feature introduces important limitations, particularly concerning the model’s generalization ability. In practical applications, such as early fraud detection or predictive monitoring of newly published work, the true retraction status is unknown and may not materialize for several years. Relying heavily on the Year feature may therefore cause the model to overemphasize temporal patterns rather than substantive indicators of scientific quality or misconduct. This can result in unfair penalization of recent papers or overconfidence in classifying older papers as likely retracted, especially if the dataset is not balanced across publication years.

In this work, Year was retained for exploratory modeling and interpretability purposes. Its inclusion offers valuable insight into temporal dynamics and supports feature ranking analyses. However, for deployment in real-world retraction detection systems, its use should be carefully reconsidered. To mitigate risks of temporal leakage, one could either exclude the feature entirely or explicitly model retraction lag (i.e., the time between publication and retraction). This distinction is crucial when transitioning from retrospective analysis to prospective prediction settings.

=== Unexpected findings
=== Potential for improvements


== Summary of main findings
=== Answers to research questions

== Future Work
=== Suggestions for future research directions
=== Potential applications in research oversight and ethics