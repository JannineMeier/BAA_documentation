#import "@preview/acrostiche:0.5.0": acr

= Methodology<H:method>

I decided to try two different approaches to detect retracted papers. I wanted to understand how well a simple model with hand-made features would perform compared to a more complex deep learning model that works directly with the text. This comparison helped me explore both the performance and the practicality of each method.

The first approach is a classical machine learning setup. I created features from the text of the papers and I also used metadata like the publication year, the number of authors, and how many times the paper was cited. These features were then used in a simple model like logistic regression or random forest. This method is easier to understand and faster to run. It also allows me to see which features might be helpful for detecting retractions.

The second approach is based on deep learning. Here, I used a transformer model and gave it only the raw text of the papers, for example the abstract or full text. This model can learn patterns in the language without needing any hand-crafted features. It is more powerful and often gives better results in text classification tasks. However, it also needs more computing power and is harder to explain.

By using both approaches, I wanted to see whether a simple and transparent model could be good enough, or if the deep learning model brings a big improvement. This comparison helped me learn more about the strengths and weaknesses of each method.

