# storyStackr
identify and diversify topics in your wattpad story

4000+ stories scraped from wattpad.com, the world's largest writing community. Wattpad is a story repository and social network where we can not only scrape author-provided tags, summaries, and chapters (the latter not yet done), but also meta data like the number of times a sotry was read and how many upvotes it received.

storyStackr.R: code for 
(1) cleaning and processing the scraped data, 
(2) running various versions of the structural topic model (with and without topic assignment regression on document metadata (particularly votes), and using KL-divergence to decide number of topics), 
(3) creating the document-topic and topic- term matrices that are collated in the "master... .csv" file in this folder (for app front-end), and 
(4) a few validation measures and data visualizations (e.g. word clouds for front end)
