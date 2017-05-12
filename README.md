Topic Modeling Hub
============
This is the central repository for literature on and applications of the topic modeling methodology. 
This page was specifically designed for the workshop on topic modeling that took place at the 2017 Academy of Management Meeting, 
but is open to anyone interested. 

Table of Contents
============

-   [Introduction](#introduction)
-   [Key articles](#articles)
    -   [Method](#method)
    -   [Applications](#applications)
-   [Working with R](#r-basics)
-   [Workshop examples](#examples)
    -   [Trump tweets](#trump-tweets)


Introduction
=====================

Key articles
=====================
Method
-------------------
Applications
-------------------

Working with R
=====================

Workshop examples
=====================
Trump tweets
-------------------
Code tested and written for R version 3.4, tm package version 0.7-1, topicmodels package version 0.2-6.
Code prepared on May 10, 2017 by Richard Haans (haans@rsm.nl).
Data obtained on May 10th using http://www.trumptwitterarchive.com/

### Package installation
## The "tm" package enables the text mining infrastructure that we will use for LDA.
if (!require("tm")) install.packages("tm")
## The "topicmodels" package enables LDA analysis.
if (!require("topicmodels")) install.packages("topicmodels")
## The cluster package and igraph package will be used at the end of this code.
if (!require("cluster")) install.packages("cluster")
if (!require("igraph")) install.packages("igraph")

### Get the data, turn into a corpus, and clean it up
# Load data from a URL
data <- read.csv(url("https://raw.githubusercontent.com/RFJHaans/topicmodeling/master/trumptweets.csv"))

# Create a corpus. 
corpus <- VCorpus((VectorSource(data[, "text"])))

# Basic cleaning (step-wise)
# We write everything to a new corpus called "corpusclean" so that we do not lose the original data.
# 1) Remove numbers
corpusclean <- tm_map(corpus, removeNumbers)
# 2) Remove punctuation
corpusclean <- tm_map(corpusclean, removePunctuation)
# 3) Transform all upper-case letters to lower-case.
corpusclean <- tm_map(corpusclean,  content_transformer(tolower))
# 4) Remove stopwords which do not convey any meaning.
corpusclean <- tm_map(corpusclean, removeWords, stopwords("english")) # this stopword file is at C:\Users\[username]\Documents\R\win-library\[rversion]\tm\stopwords 
# 5) And strip whitespace. 
corpusclean <- tm_map(corpusclean , stripWhitespace)

# See the help of getTransformations for more possibilities, such as stemming. 

# To speed up the computation process for this tutorial, I have selected some choice words that were very common:
# We update the corpusclean corpus by removing these words. 
corpusclean <- tm_map(corpusclean, removeWords, c("back","thank","now","make america great again",
                                                  "will","amp","just","new","make","like","america",
                                                  "great","hashtagtrump","atrealdonaldtrump","get",
                                                  "hashtagmakeamericagreatagain","donald",
                                                  "trump"))

## Adding metadata from the original database
# This needs to be done because transforming things into a corpus only uses the texts.
i <- 0
corpusclean = tm_map(corpusclean, function(x) {
  i <<- i +1
  meta(x, "ID") <- data[i,"ID"]
  x
})

i <- 0
corpusclean = tm_map(corpusclean, function(x) {
  i <<- i +1
  meta(x, "android") <- data[i,"android"]
  x
})

i <- 0
corpusclean = tm_map(corpusclean, function(x) {
  i <<- i +1
  meta(x, "retweets") <- data[i,"retweet_count"]
  x
})

# The above is a loop that goes through all files ("i") in the corpus
# and then maps the information of the metadata dataframe 
# (the "ID" column, et cetera) to a new piece of metadata in the corpus
# which we also call "ID", et cetera.

# This enables making selections of the corpus based on metadata now.
# Let's say we want to only look at articles from before 2011, then we do the following:
# For example:

keep <- meta(corpusclean, "android") == "1"
corpus.android <- corpusclean[keep]

keep2 <- meta(corpusclean, "android") == "0"
corpus.other <- corpusclean[keep2]

# This subsets the corpus into Android-origin tweets, and other tweets, based on the "android" metadata

# We then convert the corpus to a "Document-term-matrix" (dtm)
dtm <-DocumentTermMatrix(corpusclean)  
dtm
# dtms are organized with rows being documents and columns being the unique words.
# We can see here that the longest word in the corpus is 35 characters long.
# There are 4037 documents, containing 8799 unique words.

# Let's check out the first two tweets in our data (rows in the DTM) and the 250th to 300th words:
inspect(dtm[1:2,250:300])
# These two tweets do not contain any of the listed words (all values are zero).

# The step below is done to ensure that after removing various words, no documents are left empty 
# (LDA does not know how to deal with empty documents). 
rowTotals <- apply(dtm , 1, sum)
# This sums up the total number of words in each of the documents, e.g.:
rowTotals[1:10]
# shows the number of words for the first ten tweets.

# Then, we keep only those documents where the sum of words is greater than zero.
dtm   <- dtm[rowTotals> 0, ]
dtm
# As we can see, some documents have been removed: there are 4028 tweets left.  
