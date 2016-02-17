# quick and dirty check for Wattpad-crawled data
wattpad <- read.csv('Wattpad_crawled_160120.csv', quote = "", header=TRUE);
# wattpad_clean <- wattpad[which(is.numeric(wattpad$number_votes))]
votes = as.numeric(wattpad$number_votes)

#create columns with combined tags and summary data
wattpad$tags_summary <- do.call(paste, c(wattpad[c("tags", "summary")], sep = " ")) 

#remove meaningless string header from top of comments_and_summary_block
wattpad_clean <- as.data.frame(sapply(wattpad,gsub,pattern="Start Reading My Lists New Reading List +",replacement=""))
#remove "#d* from ratings labels
wattpad_clean <- as.data.frame(sapply(wattpad_clean, gsub, pattern = "#[0-9]*", replacement = ""))
#remove "All Rights Reserved", "", "(CC) Attrib. NonComm. NoDerivs", "Random", "Creative Commons (CC) Attribution" "(CC) Attribution-NoDerivs"
bad_genre_labels <- c("All Rights Reserved", "", "(CC) Attrib. NonComm. NoDerivs", "Random", 
                      "Creative Commons (CC) Attribution", "(CC) Attribution-NoDerivs")
wattpad_labels <- wattpad_clean[!(wattpad_clean$rating %in% bad_genre_labels),]
wattpad_labels<-wattpad_labels[!grepl("Random", wattpad_labels$rating),]

#remove all docs with no tags
wattpad_labels <- wattpad_labels[!(is.na(wattpad_labels$tags) | wattpad_labels$tags==""),]
#remove all docs with no summary
wattpad_labels <- wattpad_labels[!(is.na(wattpad_labels$summary) | wattpad_labels$summary==""),]

#data subset by genre
wattpad_action <- wattpad_labels[which(as.character(wattpad_labels$rating)==' Action'),]
wattpad_advent <- wattpad_labels[which(as.character(wattpad_labels$rating)==' Adventure'),]

#aggregate rows by genre, for each group=genre, compute mean votes, reads, and doc counts
library(plyr)
wattpad_labels$dummy_count <- rep(1, nrow(wattpad_labels))
genre_describe <- ddply(wattpad_labels, ~rating, summarise, avg_votes=mean(number_votes), 
                        avg_reads=mean(number_reads),count_docs = sum(dummy_count))
library(reshape2)
by_genre <- melt(genre_describe, id="rating")
means <- ddply(by_genre, ~variable, summarise, mean = mean(value))
library(ggplot2)
ggplot(by_genre, aes(rating, value)) + geom_bar(stat = "identity") +
#   geom_hline(aes(yintercept = mean(value))) +
  facet_wrap(~variable, ncol = 1, scales = "free_y") +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  geom_hline(aes(yintercept = mean), data = means)



hist(as.numeric(wattpad_labels$number_votes))
hist(as.numeric(wattpad_labels$number_reads))

wattpad_labels$number_reads = as.numeric(wattpad_labels$number_reads)
wattpad_labels$number_votes = as.numeric(wattpad_labels$number_votes)
# wattpadreads300 <- wattpad_labels[which(wattpad_labels$number_reads>300),]
# library(ggplot2)
# ggplot(wattpad_labels, aes(wattpad_labels$number_reads, wattpad_labels$number_votes)) +
#   geom_point() +
#   geom_smooth()
# 
# ggplot(wattpadreads300, aes(wattpadreads300$number_reads, wattpadreads300$number_votes)) +
#   geom_point() +
#   geom_smooth()
  

library("stm")

#stopword removal, etc. - for tags, try not stemming, not making lowercase
# processed <- textProcessor(wattpad$comments_and_summary_block, metadata=wattpad)
processed_tags <- textProcessor(wattpad_labels$tags, metadata=wattpad_labels)
processed_summary <- textProcessor(wattpad_labels$summary, metadata=wattpad_labels)
processed_tags_summary <- textProcessor(wattpad_labels$tags_summary, metadata=wattpad_labels)
# processed_tagsAdvent <- textProcessor(wattpad_advent$tags, metadata=wattpad_advent)

#structure and index for usage in the stm model. Verify no-missingness.
out_tags <- prepDocuments(processed_tags$documents, processed_tags$vocab, processed_tags$meta)
out_summary <- prepDocuments(processed_summary$documents, processed_summary$vocab, processed_summary$meta)
out_tags_summary <- prepDocuments(processed_tags_summary$documents, processed_tags_summary$vocab, processed_tags_summary$meta)
# out_tagsAdvent <- prepDocuments(processed_tagsAdvent$documents, processed_tagsAdvent$vocab, processed_tagsAdvent$meta)


#output will have object meta, documents, and vocab
#corpus should now have 2101 documents, 1655 terms and 14420 tokens (tags) OR
# 2089 documents, 6454 terms and 138538 tokens (comments_and_summary_block)

names(processed_tags)
# docs <- out$documents
# vocab <- out$vocab
# meta <-out$meta

## 
tagsPrev <- stm(out_tags$documents, out_tags$vocab, K = 0, 
                prevalence =~ out_tags$meta$rating + out_tags$meta$number_votes, 
                max.em.its = 500, 
                data = out_tags$meta, 
                init.type = "Spectral", 
                seed = 160126)

tagsPrevInter <- stm(out_tags$documents, out_tags$vocab, K = 0, 
                prevalence =~ out_tags$meta$rating + out_tags$meta$number_votes, 
                max.em.its = 500, 
                data = out_tags$meta, 
                init.type = "Spectral", 
                interactions = TRUE,
                seed = 160126)
tagsNoPrev <- stm(out_tags$documents, out_tags$vocab, K = 0, 
                max.em.its = 500, 
                data = out_tags$meta, 
                init.type = "Spectral", 
                seed = 160126)
# print out top words in each topic
tagsPrev10 <- labelTopics(tagsPrev,n=10) #$prob, $frex

##________Terms by Topics_____
# write.csv(tagsPrev10$prob, 'tagsPrevLabels10.csv')
# print(head(labelTopics(tagsPrev,n=10),1))
# lapply(head(labelTopics(tagsPrev,n=1),1), write, "tagsPrevLabels.csv", append=TRUE, ncolumns=6)
plot.STM(tagsPrev,type="summary", xlim=c(0,.3))
plot.STM(tagsNoPrev,type="summary", xlim=c(0,.3))


plot.STM(tagsPrev,type="perspectives", topics = c(38,39))



# tagsPrevCont <- stm(out_tags$documents, out_tags$vocab, K = 0, prevalence =~ out_tags$meta$rating + out_tags$meta$number_votes, content =~ out_tags$meta$rating, max.em.its = 500, data = out_tags$meta, init.type = "Spectral", seed = 160126)
# tagsCont <- stm(out_tags$documents, out_tags$vocab, K = 0, content =~ out_tags$meta$rating, max.em.its = 500, data = out_tags$meta, init.type = "Spectral", seed = 160126)

summaryPrev <- stm(out_summary$documents, out_summary$vocab, K = 0, 
                       prevalence =~ out_summary$meta$rating + out_summary$meta$number_votes, 
                       max.em.its = 500, 
                       data = out_summary$meta, 
                       init.type = "Spectral", 
                       seed = 160126)

tags_summaryPrev <- stm(out_tags_summary$documents, out_tags_summary$vocab, K = 0, 
                       prevalence =~ out_tags_summary$meta$rating + out_tags_summary$meta$number_votes, 
                       max.em.its = 500, 
                       data = out_tags_summary$meta, 
                       init.type = "Spectral", 
                       seed = 160126)
write.csv(tags_summaryPrev$theta, file = "tags_sums_KL_theta.csv")
plot.STM(tags_summaryPrev,type="summary", xlim=c(0,.3))

tags_summaryPrev30 <- stm(out_tags_summary$documents, out_tags_summary$vocab, K = 30, 
                        prevalence =~ out_tags_summary$meta$rating + out_tags_summary$meta$number_votes, 
                        max.em.its = 500, 
                        data = out_tags_summary$meta, 
                        init.type = "Spectral", 
                        control = list(eta = 0.01),
                        seed = 160127)
labelTopics(tags_summaryPrev20)
plot.STM(tags_summaryPrev,type="summary", xlim=c(0,.3))


##________Topics by Genre_____
topics_documents <- as.data.frame(tagsPrev$theta) #this checks out as returning same output ranks
# as plot.stm (rows = topic numbers)
genres_documents <- as.data.frame(out_tags$meta$rating) #genre labels from data source file
colnames(genres_documents) <- c("genre")
topic_genre_docs <- cbind(genres_documents,topics_documents) #stick genre labels on there

write.csv(topic_genre_docs, 'topicxdocument_genre_labeled.csv')

#aggregate document topic proportions by genre
topics_byGenre <- aggregate(topic_genre_docs[,2:45], list(topic_genre_docs$genre), mean)
#normalize so proportions add up to one
topics_byGenre_norm <-apply(topics_byGenre[,2:ncol(topics_byGenre)], 1, function(x) x/sum(x))
#label the columns by genre (rows are topics, which will be index in pandas)
colnames(topics_byGenre_norm) <- as.character(topics_byGenre[,1])
# write.csv(topics_byGenre_norm, 'topics_byGenre.csv')


##________Representative docs by topic_____
# This returns the document the most words of which are assigned to the given topic. 
# Concretely, it returns the top document ranked by the MAP estimate of the topic's 
# theta value (which captures the modal estimate of the proportion of word tokens 
# assigned to the topic under the model). 
repSummariesByTopic <- findThoughts(tagsPrev, texts = as.character(out_tags$meta$summary),n = 1)
repURLsByTopic <- findThoughts(tagsPrev, texts = as.character(out_tags$meta$X_pageUrl),n = 1)
repSummariesByTopic <- cbind(as.data.frame(repSummariesByTopic), as.data.frame())

repdoc_ind <- as.data.frame(repSummariesByTopic$index)
urls <- t(as.data.frame(repURLsByTopic$docs))
repdoc_sums <- t(as.data.frame(repSummariesByTopic$docs))

# Make all topics row indices commensurate across dataframes
repDocsByTopic <- cbind(repdoc_ind, repdoc_sums, urls)
colnames(repDocsByTopic)[1] <- 'document_number'

write.csv(repDocsByTopic, "representativeDocsByTopic.csv")

rownames(topics_byGenre_norm) <- rownames(repDocsByTopic)
write.csv(topics_byGenre_norm, 'topics_byGenre.csv')

terms_by_topics <- tagsPrev10$prob
rownames(terms_by_topics) <- rownames(repDocsByTopic)
colnames(terms_by_topics) <-c('term1', 'term2','term3','term4','term5','term6','term7','term8','term9','term10')
terms_by_topics <-as.data.frame(terms_by_topics)
within(terms_by_topics, terms_by_topics$term_str <- paste(term1, term2, term3, term4, 
                                                          term5, term6, term7, term8, 
                                                          term9, term10, sep=', '))
write.csv(terms_by_topics, 'tagsPrevLabels10.csv')

# #Look at some correlations between topics__NOT GREAT FOR VISUALIZATION
# library(huge)
tagsPrev_corr_matrix_huge = topicCorr(tagsPrev, method = "huge")
tagsPrev_corr_matrix = topicCorr(tagsPrev, method = "simple")

plot.topicCorr(tagsPrev_corr_matrix)
# ehh... ?

# correlation matrix____________________________________________________________
library(reshape2)
# tagsPrev_corr_matrix <- as.numeric(tagsPrev_corr_matrix)
# cormat <- tagsPrev_corr_matrix$cor
# cormat <- tagsPrev$sigma
cormat <- cor(t(tagsPrev$theta))
# melted_corr <- melt(cormat)
# library(ggplot2)
# ggplot(data = melted_corr, aes(x=Var1, y=Var2, fill=value)) + 
#   geom_tile()
# 
# 
# # Get upper triangle of the correlation matrix
# get_upper_tri <- function(cormat){
#   cormat[lower.tri(cormat)]<- NA
#   return(cormat)
# }
# upper_tri <- get_upper_tri(cormat)
# 
# # Melt the correlation matrix
# library(reshape2)
# melted_cormat <- melt(upper_tri, na.rm = TRUE)
# 
# # Heatmap
# library(ggplot2)
# ggplot(data = melted_cormat, aes(x=Var2, y=Var1, fill = value))+
#   geom_tile(color = "white")+
# #   scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
# #                        midpoint = 0, limit = c(-1,1), space = "Lab", 
# #                        name="Pearson\nCorrelation") +
#   theme_minimal()+ 
#   theme(axis.text.x = element_text(angle = 45, vjust = 1, 
#                                    size = 12, hjust = 1))+
#   coord_fixed()
# 
# 
# #####Works up to this point___________________
reorder_cormat <- function(cormat){
  # Use correlation between variables as distance
  dd <- as.dist((1-cormat)/2)
  hc <- hclust(dd)
  cormat <-cormat[hc$order, hc$order]
}

# REALLY ONLY NEED THIS Reorder the correlation matrix *************************
cormat <- reorder_cormat(cormat)
# upper_tri <- get_upper_tri(cormat)

# Melt the correlation matrix
# melted_cormat <- melt(upper_tri, na.rm = TRUE)
melted_cormat <- melt(cormat, na.rm = TRUE)


# Create a ggheatmap
ggheatmap <- ggplot(melted_cormat, aes(Var2, Var1, fill = value))+
  geom_tile(color = "white")+
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                       midpoint = 0, limit = c(-1,1), space = "Lab", 
                       name="Pearson\nCorrelation") +
  theme_minimal()+ # minimal theme
  theme(axis.text.x = element_text(angle = 45, vjust = 1, 
                                   size = 12, hjust = 1))+
  coord_fixed()

# Print the heatmap
print(ggheatmap)


##### WORD CLOUDS ######
for(i in 1:tagsPrev$settings$dim$K){ 
  mypath <- file.path("topic_imgs",paste("topic", as.character(i), ".png", sep = ""))
  png(file=mypath)
    mytitle = paste("topic", as.character(i))
    topiccloud <-cloud(tagsPrev, topic = i, max.words=20, scale = c(3,1)) #534 x 424
  dev.off()
  }


# 
# 
# #DOESN'T WORK________________________________________________________________________
# #following stuff actually easier in numpy
# topics_ordered<-apply(topics_byGenre, 1, function(x) order(x[2:45], decreasing=T))
# topicvals_ordered<-t(apply(topics_byGenre, 1, function(x) sort(x[2:45])))
# 
# 
# # topics_ordered<-t(apply(topics_byGenre, 1, function(x) order(x[2:45])))
# topic_genre_docINDS <-cbind(as.data.frame(topics_byGenre[,1]),topics_ordered)
# 
# tagsPrev <- stm(out_tags$documents, out_tags$vocab, K = 0, 
#                 prevalence =~ out_tags$meta$rating + out_tags$meta$number_votes, 
#                 max.em.its = 500, 
#                 data = out_tags$meta, 
#                 init.type = "Spectral", 
#                 seed = 160126)