= Appendix

== Full feature documentation and formulas
== Hyperparameter configurations
== Sample visualizations and charts
== Links to code repositories and logs (e.g. W&B runs)

== Used Tools<H:used_tools>

During programming, the following tools were used:
- GitHub Copilot#footnote[https://github.com/features/copilot]

For proofreading, the following tools were used:
- Grammarly#footnote[https://www.grammarly.com/]

== Code
```python
import os

import numpy as np

def hello_world():
	print("Hello, World!")
```

== Significance Values


Top 50 Most Influential Features (Sorted by |mean coefficient|):

                                                                                                                                mean       std   abs_mean  t_like_score
incoming_citations_count                                                                                                  -19.532752  0.258229  19.532752    -75.641107
mean_citation_context_to_cited_abstract_l2_distance_y                                                                       2.525361  0.081669   2.525361     30.921991
outgoing_citations_count                                                                                                   -2.447346  0.056706   2.447346    -43.158161
max_abstract_to_cited_abstract_l2_distance_y                                                                               -1.796742  0.078776   1.796742    -22.808287
Year                                                                                                                       -1.695058  0.050708   1.695058    -33.427528
max_citation_context_to_cited_abstract_l2_distance_y                                                                       -1.478206  0.117881   1.478206    -12.539800
num_authors                                                                                                                -1.283778  0.082720   1.283778    -15.519568
hc_ft_28_short_word_ratio                                                                                                   0.980233  0.105565   0.980233      9.285624
hc_ft_27_long_word_ratio                                                                                                    0.974197  0.158736   0.974197      6.137210
mean_abstract_to_cited_abstract_l2_distance_y                                                                               0.908811  0.147012   0.908811      6.181874
country_Korea, Republic of                                                                                                 -0.825906  0.050964   0.825906    -16.205791
Field_threshold_Biochemistry, Genetics and Molecular Biology                                                                0.705223  0.042431   0.705223     16.620480
0                                                                                                                           0.700966  0.026159   0.700966     26.796318
hc_ft_07_type_token_ratio                                                                                                  -0.666155  0.062955   0.666155    -10.581445
hc_ft_04_stopword_ratio                                                                                                    -0.619456  0.133553   0.619456     -4.638290
1                                                                                                                          -0.617481  0.018682   0.617481    -33.051485
hc_25_adj_count                                                                                                            -0.537216  0.038111   0.537216    -14.095956
country_China                                                                                                               0.508057  0.037896   0.508057     13.406636
hc_ft_00_char_count                                                                                                         0.501201  0.104839   0.501201      4.780672
Field_threshold_Medicine                                                                                                    0.491258  0.018473   0.491258     26.593836
country_United States                                                                                                      -0.486572  0.042686   0.486572    -11.398841
2                                                                                                                          -0.480372  0.033189   0.480372    -14.473981
author_James E Hunton                                                                                                       0.472265  0.075458   0.472265      6.258638
author_Diederik A Stapel                                                                                                    0.464985  0.048456   0.464985      9.595930
country_United Kingdom                                                                                                     -0.459562  0.034612   0.459562    -13.277416
author_Joachim Boldt                                                                                                        0.453204  0.033490   0.453204     13.532498
7                                                                                                                           0.439943  0.035449   0.439943     12.410494
hc_01_word_count                                                                                                            0.418765  0.081399   0.418765      5.144586
8                                                                                                                          -0.410978  0.030957   0.410978    -13.275737
country_Canada                                                                                                             -0.405056  0.041190   0.405056     -9.833800
num_countries                                                                                                               0.403616  0.107723   0.403616      3.746787
Field_threshold_Computer Science                                                                                           -0.375303  0.011162   0.375303    -33.622270
author_Clara E Hill                                                                                                         0.354073  0.041165   0.354073      8.601335
author_Ali Nazari                                                                                                           0.351501  0.036088   0.351501      9.740053
hc_22_comma_count                                                                                                          -0.335779  0.062715   0.335779     -5.354069
author_Yoshitaka Fujii                                                                                                      0.332521  0.040692   0.332521      8.171729
inst_and                                                                                                                   -0.331464  0.045816   0.331464     -7.234625
hc_07_type_token_ratio                                                                                                     -0.325374  0.026155   0.325374    -12.440137
Domain_threshold_Physical Sciences                                                                                         -0.319699  0.009087   0.319699    -35.180216
11                                                                                                                          0.305031  0.023568   0.305031     12.942514
14                                                                                                                         -0.304186  0.015293   0.304186    -19.891185
inst_Department of Agronomy, Bahauddin Zakariya University, Multan, Pakistan                                                0.296516  0.033281   0.296516      8.909497
hc_ft_14_pronoun_we_count                                                                                                  -0.287552  0.025062   0.287552    -11.473612
country_Australia                                                                                                          -0.280153  0.058531   0.280153     -4.786443
21                                                                                                                         -0.266860  0.029290   0.266860     -9.111060
inst_Department of Botany and Microbiology, College of Science, King Saud University, Riyadh, Saudi Arabia                  0.259417  0.023938   0.259417     10.837035
country_Denmark                                                                                                            -0.257070  0.019754   0.257070    -13.013544
inst_Department of Computer Science and Engineering, Sri Krishna College of Engineering and Technology, Coimbatore, India   0.255420  0.032412   0.255420      7.880429
hc_ft_03_stopword_count                                                                                                     0.252332  0.102618   0.252332      2.458944
Field_threshold_Immunology and Microbiology                                                                                 0.250558  0.023935   0.250558     10.468173

Accuracy by Feature Group:

       Feature Group  Mean Accuracy  Std Accuracy  Num Features
            citation       0.958477      0.000914             3
    country_binaries       0.834027      0.001834            21
           embedding       0.779714      0.002724            64
handcrafted_abstract       0.771624      0.005741            30
handcrafted_fulltext       0.733611      0.011509            30
          similarity       0.718620      0.003734             4
         meta_counts       0.666865      0.004562             3
                year       0.580726      0.006980             1
domain_field_dummies       0.553242      0.008783            28
     author_binaries       0.545509      0.003192           101
institution_binaries       0.525223      0.002284            51