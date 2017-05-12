Topic Modeling Hub
============
This is a repository for literature on and applications of the topic modeling methodology. 
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
Brief introduction on the aims of the page etc.

Key articles
=====================
Method
-------------------
Articles on the method of topic modeling.

Applications
-------------------
Articles applying topic modeling.

Working with R
=====================
Here some content on working with R will be located. 

Workshop examples
=====================
Trump tweets
-------------------
Code tested and written for R version 3.4, tm package version 0.7-1, topicmodels package version 0.2-6.
Code prepared on May 10, 2017 by Richard Haans (haans@rsm.nl).
Data obtained on May 10th using http://www.trumptwitterarchive.com/

### Package installation

```Rscript
# The "tm" package enables the text mining infrastructure that we will use for LDA.
    if (!require("tm")) install.packages("tm")

# The "topicmodels" package enables LDA analysis.
    if (!require("topicmodels")) install.packages("topicmodels")
    
# The cluster package and igraph package will be used at the end of this code.
    if (!require("cluster")) install.packages("cluster")
    if (!require("igraph")) install.packages("igraph")
```

### Get the data, turn into a corpus, and clean it up

```Rscript
### Load data from a URL
    data = read.csv(url("https://raw.githubusercontent.com/RFJHaans/topicmodeling/master/trumptweets.csv"))

### Create a corpus. 
    corpus = VCorpus((VectorSource(data[, "text"])))

### Basic cleaning (step-wise)
# We write everything to a new corpus called "corpusclean" so that we do not lose the original data.
# 1) Remove numbers
    corpusclean = tm_map(corpus, removeNumbers)
# 2) Remove punctuation
    corpusclean = tm_map(corpusclean, removePunctuation)
# 3) Transform all upper-case letters to lower-case.
    corpusclean = tm_map(corpusclean,  content_transformer(tolower))
# 4) Remove stopwords which do not convey any meaning.
    corpusclean = tm_map(corpusclean, removeWords, stopwords("english"))
# this stopword file is at C:\Users\[username]\Documents\R\win-library\[rversion]\tm\stopwords 
# 5) And strip whitespace. 
    corpusclean = tm_map(corpusclean , stripWhitespace)

# See the help of getTransformations for more possibilities, such as stemming. 

# To speed up the computation process for this tutorial, I have selected some choice words that were very common:
# We update the corpusclean corpus by removing these words. 
    corpusclean = tm_map(corpusclean, removeWords, c("back","thank","now","make america great again",
                                                      "will","amp","just","new","make","like","america",
                                                      "great","hashtagtrump","atrealdonaldtrump","get",
                                                      "hashtagmakeamericagreatagain","donald",
                                                      "trump"))

### Adding metadata from the original database
# This needs to be done because transforming things into a corpus only uses the texts.
    i = 0
    corpusclean = tm_map(corpusclean, function(x) {
      i <<- i +1
      meta(x, "ID") = data[i,"ID"]
      x
    })

    i = 0
    corpusclean = tm_map(corpusclean, function(x) {
      i <<- i +1
      meta(x, "android") = data[i,"android"]
      x
    })

# The above is a loop that goes through all files ("i") in the corpus
# and then maps the information of the metadata dataframe 
# (the "ID" column, et cetera) to a new piece of metadata in the corpus
# which we also call "ID", et cetera.

# This enables making selections of the corpus based on metadata now.
# Let's say we want to only look at articles from before 2011, then we do the following:
# For example:
    keep = meta(corpusclean, "android") == "1"
    corpus.android = corpusclean[keep]

    keep2 = meta(corpusclean, "android") == "0"
    corpus.other = corpusclean[keep2]
# This subsets the corpus into Android-origin tweets, and other tweets, based on the "android" metadata

# We then convert the corpus to a "Document-term-matrix" (dtm)
    dtm = DocumentTermMatrix(corpusclean)  
    dtm
```

```Ruby
<<DocumentTermMatrix (documents: 4037, terms: 8799)>>
Non-/sparse entries: 36042/35485521
Sparsity           : 100%
Maximal term length: 35
Weighting          : term frequency (tf)
```

```Rscript
# dtms are organized with rows being documents and columns being the unique words.
# We can see here that the longest word in the corpus is 35 characters long.
# There are 4037 documents, containing 8799 unique words.

# Let's check out the first two tweets in our data (rows in the DTM) and the 250th to 300th words:
    inspect(dtm[1:2,250:300])
```

```Ruby
    Terms
Docs another answer answered answering answers anthony anti antia
   1       0      0        0         0       0       0    0     0
   2       0      0        0         0       0       0    0     0
    Terms
Docs anticatholic anticipated
   1            0           0
   2            0           0
```

```Rscript
# These two tweets do not contain any of the listed words (all values are zero).

# The step below is done to ensure that after removing various words, no documents are left empty 
# (LDA does not know how to deal with empty documents). 
    rowTotals = apply(dtm , 1, sum)
# This sums up the total number of words in each of the documents, e.g.:
    rowTotals[1:10]
# shows the number of words for the first ten tweets.    
```

```Ruby
 1  2  3  4  5  6  7  8  9 10 
 4 11 12 10  6  6  5 12  9 10
```

```Rscript


# Then, we keep only those documents where the sum of words is greater than zero.
    dtm = dtm[rowTotals> 0, ]
    dtm
# Shows that some documents have been removed: there are 4028 tweets left.      
```

```Ruby
<<DocumentTermMatrix (documents: 4028, terms: 8799)>>
Non-/sparse entries: 36042/35406330
Sparsity           : 100%
Maximal term length: 35
Weighting          : term frequency (tf)
```

### Infrequent words and frequent words
```Rscript
# Next, we will assess which words are most frequent:
    highfreq100 = findFreqTerms(dtm,100,Inf)
# This creates a vector containing words from the dtm that occur 100 or more time (100 to infinity times)
# In the top-right window, we can see that there are 26 words occurring more than 100 times.
# Let's see what words these are:
    highfreq100
```    

```Ruby    
 [1] "bad"       "big"       "can"       "clinton"   "country"   "crooked"   "cruz"     
 [8] "going"     "hillary"   "join"      "last"      "many"      "media"     "never"    
[15] "one"       "people"    "poll"      "president" "said"      "ted"       "time"     
[22] "today"     "tomorrow"  "tonight"   "vote"      "win"
```    

```Rscript
# We can create a smaller dtm that makes the following two selections on the words in the corpus:
# In this example, we won't actually use this smaller DTM since tweets are already very short,
# but it is useful for typical topic modeling applications.
# 1) Keep only those words that occur more than 50 times.
    minoccur = 50
# 2) Keep only those words that occur in at least 5 of the documents. 
    mindocs = 5
# Note that this is completed on the corpus, not the DTM. 
    smalldtm_50w_5doc = DocumentTermMatrix(corpusclean, control=list(dictionary = findFreqTerms(dtm,minoccur,Inf), 
                                                                      bounds = list(global = c(mindocs,Inf))))

    rowTotals = apply(smalldtm_50w_5doc , 1, sum)
    smalldtm_50w_5doc   = smalldtm_50w_5doc[rowTotals> 0, ]
```  
### LDA: Running the model
```Rscript
# We first fix the random seed to for future replication.
    SEED = 123456789

# Here we define the number of topics to be estimated. I find fifty provides decent results, while much lower 
# leads to messy topics with little variation. 
# However, little theory or careful investigation went into this so be wary.
    k = 50

# We then create a variable which captures the starting time of this particular model.
    t1_LDA50 = Sys.time()
# And then we run a LDA model with 15 topics (k = 15).
# Note that the input is the dtm
    LDA50 = LDA(dtm, k = k, control = list(seed = SEED))
# And we create a variable capturing the end time of this model.
    t2_LDA50 = Sys.time()

# We can then check the time difference to see how long the model took. 
    t2_LDA50 - t1_LDA50
```

```Ruby  
Time difference of 11.02499 mins
```

In this example, I use the VEM algorithm to estimate the topic model. Note that an alternative algorithm, using Gibbs sampling, is also available in the topicmodels package. However, time constraints preclude a full appreciation of this approach during the workshop. The topicmodels package has good documentation on estimating a topic model using the Gibbs sampling approach.

### LDA: The output
```Rscript
# We then create a variable that captures the top ten terms assigned to the 15-topic model:
    topics_LDA50 = terms(LDA50, 10)
# And show the results:
    topics_LDA50
```

```Ruby  
      Topic 1  Topic 2       Topic 3     Topic 4            Topic 5           Topic 6     
 [1,] "said"   "hillary"     "american"  "hashtagimwithyou" "watching"        "media"     
 [2,] "say"    "clinton"     "senator"   "two"              "nevada"          "dishonest" 
 [3,] "rigged" "crooked"     "phony"     "convention"       "arizona"         "supporters"
 [4,] "safe"   "voter"       "help"      "others"           "think"           "election"  
 [5,] "system" "fraud"       "talk"      "california"       "atoreillyfactor" "nice"      
 [6,] "dems"   "poor"        "warren"    "crowds"           "atseanhannity"   "remember"  
 [7,] "major"  "sent"        "hope"      "tuesday"          "fact"            "things"    
 [8,] "real"   "problems"    "goofy"     "continue"         "nobody"          "leaving"   
 [9,] "answer" "temperament" "elizabeth" "atgreta"          "usa"             "statement" 
[10,] "guns"   "serious"     "senate"    "respect"          "beautiful"       "always"  

      Topic 7   Topic 8       Topic 9   Topic 10    Topic 11               
 [1,] "obama"   "join"        "cruz"    "morning"   "see"                  
 [2,] "really"  "hashtagmaga" "today"   "everyone"  "soon"                 
 [3,] "lies"    "ohio"        "ted"     "didnt"     "together"             
 [4,] "family"  "tomorrow"    "deal"    "keep"      "hashtagbigleaguetruth"
 [5,] "looks"   "tickets"     "lyin"    "million"   "work"                 
 [6,] "rallies" "colorado"    "book"    "primary"   "hashtagdebate"        
 [7,] "air"     "atmikepence" "problem" "also"      "next"                 
 [8,] "went"    "wins"        "canada"  "lie"       "event"                
 [9,] "met"     "maine"       "born"    "terrorism" "team"                 
[10,] "came"    "rapids"      "signed"  "fix"       "taking"               

      Topic 12               Topic 13     Topic 14       Topic 15            Topic 16          
 [1,] "time"                 "totally"    "tonight"      "hashtagtrumppence" "hashtagvotetrump"
 [2,] "watch"                "cant"       "rally"        "hashtagiacaucus"   "even"            
 [3,] "hashtagdraintheswamp" "biased"     "virginia"     "foreign"           "news"            
 [4,] "nothing"              "general"    "evening"      "forget"            "jeb"             
 [5,] "kasich"               "case"       "heading"      "november"          "live"            
 [6,] "hashtagicymi"         "university" "unbelievable" "reporting"         "history"         
 [7,] "report"               "unfair"     "center"       "hashtagrncincle"   "bush"            
 [8,] "winning"              "stay"       "seen"         "despite"           "worse"           
 [9,] "words"                "court"      "west"         "choice"            "endorsed"        
[10,] "voted"                "justice"    "friday"       "started"           "truly"      

      Topic 17           Topic 18     Topic 19     Topic 20           Topic 21           
 [1,] "change"           "many"       "jobs"       "state"            "bad"              
 [2,] "doesnt"           "bernie"     "republican" "person"           "york"             
 [3,] "ads"              "run"        "party"      "called"           "guy"              
 [4,] "false"            "sanders"    "interview"  "terrible"         "hashtagtrumptrain"
 [5,] "athillaryclinton" "clintons"   "gave"       "email"            "fight"            
 [6,] "wrong"            "nomination" "weak"       "hashtaggopdebate" "hashtagdebates"   
 [7,] "judgement"        "treated"    "strong"     "fbi"              "attedcruz"        
 [8,] "negative"         "biggest"    "bring"      "delegates"        "open"             
 [9,] "spending"         "georgia"    "attack"     "top"              "stand"            
[10,] "spent"            "list"       "democrats"  "winner"           "high"      

      Topic 22  Topic 23    Topic 24   Topic 25     Topic 26    Topic 27 Topic 28    
 [1,] "show"    "hard"      "want"     "can"        "never"     "wow"    "atcnn"     
 [2,] "total"   "first"     "voters"   "campaign"   "money"     "job"    "running"   
 [3,] "isis"    "ever"      "law"      "look"       "wonderful" "states" "used"      
 [4,] "sad"     "kaine"     "trade"    "emails"     "millions"  "united" "place"     
 [5,] "far"     "interest"  "talking"  "forward"    "getting"   "away"   "tremendous"
 [6,] "world"   "corrupt"   "officers" "meeting"    "tax"       "word"   "asked"     
 [7,] "watched" "thing"     "order"    "washington" "wont"      "calls"  "trumps"    
 [8,] "liar"    "atjebbush" "police"   "anything"   "hillarys"  "china"  "may"       
 [9,] "joke"    "horrible"  "chance"   "funding"    "dollars"   "become" "part"      
[10,] "iran"    "nafta"     "tower"    "self"       "home"      "russia" "greatly"   

      Topic 29       Topic 30                Topic 31      Topic 32      Topic 33      
 [1,] "atmegynkelly" "support"               "hampshire"   "way"         "win"         
 [2,] "special"      "lets"                  "ratings"     "let"         "dont"        
 [3,] "stop"         "believe"               "story"       "failing"     "failed"      
 [4,] "put"          "need"                  "yesterday"   "thanks"      "presidential"
 [5,] "fox"          "bill"                  "badly"       "allowed"     "endorsement" 
 [6,] "smart"        "hashtagcrookedhillary" "cnn"         "politicians" "lost"        
 [7,] "tough"        "house"                 "hashtagfitn" "give"        "candidate"   
 [8,] "interests"    "defeat"                "questions"   "exciting"    "romney"      
 [9,] "must"         "white"                 "woman"       "lot"         "zero"        
[10,] "crazy"        "behind"                "thats"       "saw"         "mitt"      

      Topic 34    Topic 35      Topic 36   Topic 37          Topic 38     Topic 39      
 [1,] "good"      "enjoy"       "poll"     "another"         "speech"     "people"      
 [2,] "man"       "interviewed" "polls"    "atfoxandfriends" "debate"     "country"     
 [3,] "michigan"  "record"      "women"    "making"          "got"        "pennsylvania"
 [4,] "press"     "john"        "beat"     "happy"           "made"       "movement"    
 [5,] "hear"      "honor"       "votes"    "yet"             "times"      "looking"     
 [6,] "coming"    "voting"      "numbers"  "fantastic"       "texas"      "happening"   
 [7,] "politics"  "hit"         "lead"     "incredible"      "presidency" "missouri"    
 [8,] "knows"     "check"       "released" "melania"         "cleveland"  "thousands"   
 [9,] "announced" "set"         "final"    "wife"            "full"       "maryland"    
[10,] "meet"      "pme"         "radical"  "conference"      "group"      "created"     

      Topic 40              Topic 41      Topic 42       Topic 43  Topic 44          
 [1,] "carolina"            "true"        "iowa"         "years"   "vote"            
 [2,] "hashtagamericafirst" "immigration" "florida"      "done"    "big"             
 [3,] "amazing"             "illegal"     "crowd"        "take"    "day"             
 [4,] "south"               "border"      "tomorrow"     "saying"  "right"           
 [5,] "north"               "please"      "must"         "gop"     "wisconsin"       
 [6,] "massive"             "interesting" "important"    "come"    "americans"       
 [7,] "every"               "prayers"     "potus"        "worst"   "agree"           
 [8,] "plan"                "correct"     "tampa"        "economy" "congratulations" 
 [9,] "expected"            "security"    "announcement" "four"    "future"          
[10,] "httpstcokwolibaw"    "thoughts"    "complete"     "days"    "hashtagwiprimary"

      Topic 45     Topic 46      Topic 47      Topic 48       Topic 49     Topic 50    
 [1,] "atfoxnews"  "last"        "one"         "much"         "president"  "know"      
 [2,] "atnytimes"  "night"       "wants"       "better"       "going"      "best"      
 [3,] "won"        "rubio"       "shows"       "disaster"     "national"   "governor"  
 [4,] "says"       "love"        "year"        "obamacare"    "indiana"    "proud"     
 [5,] "well"       "video"       "still"       "repeal"       "mexico"     "leadership"
 [6,] "call"       "marco"       "left"        "replace"      "business"   "mike"      
 [7,] "taxes"      "little"      "without"     "told"         "close"      "pence"     
 [8,] "everything" "lightweight" "almost"      "atmorningjoe" "protect"    "trying"    
 [9,] "results"    "working"     "donaldtrump" "increase"     "government" "happen"    
[10,] "game"       "race"        "since"       "save"         "drop"       "anyone"
```

```Rscript
# We can write the results of the topics to a .csv file as follows:
# write.table(topics_LDA50, file = "50_topics", sep=',',row.names = FALSE)

# Let's now create a file containing the topic loadings for all articles:
    gammaDF_LDA50 = as.data.frame(LDA50@gamma) 
# This creates a dataframe containing for every row the articles and for every column the per-topic loading.
    gammaDF_LDA50$ID = dtm$dimnames$Docs
# We add the file number from the metadata for merging with the metadata file. Of course
# any other type of data can be added.

# If we are not necessarily interested in using the full range of topic loadings,
# but only in keeping those loadings that exceed a certain threshold, 
# then we can use the code below:
    majortopics = topics(LDA50, threshold = 0.3)
    majortopics = as.data.frame(vapply(majortopics, 
           paste, collapse = ", ", character(1L)))
    colnames(majortopics) = "topic" 
# Here, we state that we want to show all topics that load greater than 0.3, per paper.
# As far as I know, there are no clear guidelines as to what cut-off is most meaningful.
# Of course, the higher the threshold, the fewer topics will be selected per paper.
# The flattening (the second and third lines) is done to clean this column up (from e.g. "c(1,5,7)" to "1,5,7")

    majortopics$topic = sub("^$", 0, majortopics$topic)

    majortopics$ID = dtm$dimnames$Docs
    
# Some tweets may have no topics assigned to them; we replace their topic with 0. 

# NOTE: It will report the topics in a sequential manner - the first topic in this list is not
# necessarily the highest loading topic.     

# We can also select the highest loading topic for every paper by changing the threshold-subcommand
# to k = (k refers to the number of highest loading topics per paper):
    highest = as.data.frame(cbind(iphone = data$iphone, highesttopic = topics(LDA50, k = 1)))
    highest$ID = dtm$dimnames$Docs

# Create a merged dataset for some follow-up analyses:
    mergeddata = merge(data,highest,by="ID")
```

### Using the topic model output: predict Android tweets
We will use the most important topics for each tweet to see if it can predict whether or not the tweet was sent from an Android device. 
See, for example: https://www.theatlantic.com/technology/archive/2017/03/trump-android-tweets/520869/
This would suggest that "real" Trump tweets may be coming from an Android device, and differing topic usage across platforms may indicate that the tweets are coming from different sources (Trump, using Android, versus his team, using non-Android devices). 

We estimate a logit model to predict this outcome, with dummies for every topic. 
```Rscript
    model = glm(android ~factor(highesttopic),family=binomial(link='logit'),data=mergeddata)

    summary(model)
```

```Ruby
Deviance Residuals: 
    Min       1Q   Median       3Q      Max  
-1.5996  -1.0727  -0.7446   1.1407   2.0168  

Coefficients:
                        Estimate Std. Error z value Pr(>|z|)    
(Intercept)             0.123614   0.222647   0.555 0.578757    
factor(highesttopic)2   0.829816   0.294983   2.813 0.004907 ** 
factor(highesttopic)3  -0.315986   0.323844  -0.976 0.329195    
factor(highesttopic)4  -1.017432   0.318999  -3.189 0.001425 ** 
factor(highesttopic)5  -0.518927   0.316675  -1.639 0.101281    
factor(highesttopic)6   0.281851   0.337156   0.836 0.403174    
factor(highesttopic)7   0.207743   0.333057   0.624 0.532794    
factor(highesttopic)8  -2.017156   0.362977  -5.557 2.74e-08 ***
factor(highesttopic)9   0.176491   0.305107   0.578 0.562957    
factor(highesttopic)10 -0.177681   0.321971  -0.552 0.581048    
factor(highesttopic)11 -1.469634   0.340443  -4.317 1.58e-05 ***
factor(highesttopic)12 -0.374928   0.316805  -1.183 0.236624    
factor(highesttopic)13  0.610355   0.333524   1.830 0.067247 .  
factor(highesttopic)14 -0.789362   0.300811  -2.624 0.008688 ** 
factor(highesttopic)15 -1.264786   0.327015  -3.868 0.000110 ***
factor(highesttopic)16 -0.694159   0.331319  -2.095 0.036159 *  
factor(highesttopic)17 -0.075986   0.311797  -0.244 0.807461    
factor(highesttopic)18 -0.036603   0.328104  -0.112 0.911174    
factor(highesttopic)19  0.034610   0.320208   0.108 0.913927    
factor(highesttopic)20 -0.435989   0.327559  -1.331 0.183182    
factor(highesttopic)21 -0.506606   0.325011  -1.559 0.119059    
factor(highesttopic)22 -0.123614   0.329234  -0.375 0.707319    
factor(highesttopic)23 -0.123614   0.326672  -0.378 0.705130    
factor(highesttopic)24 -0.483617   0.325823  -1.484 0.137732    
factor(highesttopic)25 -0.837380   0.334135  -2.506 0.012207 *  
factor(highesttopic)26  0.767359   0.371096   2.068 0.038657 *  
factor(highesttopic)27  0.188761   0.327559   0.576 0.564437    
factor(highesttopic)28  0.087695   0.320613   0.274 0.784451    
factor(highesttopic)29  0.157799   0.305679   0.516 0.605698    
factor(highesttopic)30 -0.836564   0.330423  -2.532 0.011348 *  
factor(highesttopic)31 -0.857583   0.333524  -2.571 0.010132 *  
factor(highesttopic)32 -0.518927   0.316675  -1.639 0.101281    
factor(highesttopic)33  0.325336   0.322772   1.008 0.313481    
factor(highesttopic)34 -0.123614   0.317575  -0.389 0.697096    
factor(highesttopic)35  0.079985   0.280818   0.285 0.775775    
factor(highesttopic)36 -0.274437   0.304676  -0.901 0.367721    
factor(highesttopic)37 -0.485404   0.305073  -1.591 0.111586    
factor(highesttopic)38 -0.402327   0.335131  -1.201 0.229942    
factor(highesttopic)39 -0.539774   0.321102  -1.681 0.092761 .  
factor(highesttopic)40 -0.922122   0.299749  -3.076 0.002096 ** 
factor(highesttopic)41 -0.228974   0.319921  -0.716 0.474163    
factor(highesttopic)42 -1.098174   0.344150  -3.191 0.001418 ** 
factor(highesttopic)43 -0.034002   0.330746  -0.103 0.918119    
factor(highesttopic)44 -0.257145   0.321159  -0.801 0.423317    
factor(highesttopic)45  0.001549   0.335137   0.005 0.996312    
factor(highesttopic)46  0.271040   0.321821   0.842 0.399672    
factor(highesttopic)47  0.346390   0.361693   0.958 0.338219    
factor(highesttopic)48 -0.352456   0.317601  -1.110 0.267110    
factor(highesttopic)49 -1.186508   0.346965  -3.420 0.000627 ***
factor(highesttopic)50 -0.473816   0.323353  -1.465 0.142833    
---
Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

(Dispersion parameter for binomial family taken to be 1)

    Null deviance: 5548.8  on 4027  degrees of freedom
Residual deviance: 5249.9  on 3978  degrees of freedom
AIC: 5349.9

Number of Fisher Scoring iterations: 4
```
We will focus on the significant topics. 
```Rscript
# Topics negatively related to android:
    topics_LDA50[,c(4,8,11,14,15,16,25,30,31,40,42,49)]
```

```Ruby
      Topic 4            Topic 8       Topic 11                Topic 14       Topic 15           
 [1,] "hashtagimwithyou" "join"        "see"                   "tonight"      "hashtagtrumppence"
 [2,] "two"              "hashtagmaga" "soon"                  "rally"        "hashtagiacaucus"  
 [3,] "convention"       "ohio"        "together"              "virginia"     "foreign"          
 [4,] "others"           "tomorrow"    "hashtagbigleaguetruth" "evening"      "forget"           
 [5,] "california"       "tickets"     "work"                  "heading"      "november"         
 [6,] "crowds"           "colorado"    "hashtagdebate"         "unbelievable" "reporting"        
 [7,] "tuesday"          "atmikepence" "next"                  "center"       "hashtagrncincle"  
 [8,] "continue"         "wins"        "event"                 "seen"         "despite"          
 [9,] "atgreta"          "maine"       "team"                  "west"         "choice"           
[10,] "respect"          "rapids"      "taking"                "friday"       "started" 

      Topic 16           Topic 25     Topic 30                Topic 31      Topic 40             
 [1,] "hashtagvotetrump" "can"        "support"               "hampshire"   "carolina"           
 [2,] "even"             "campaign"   "lets"                  "ratings"     "hashtagamericafirst"
 [3,] "news"             "look"       "believe"               "story"       "amazing"            
 [4,] "jeb"              "emails"     "need"                  "yesterday"   "south"              
 [5,] "live"             "forward"    "bill"                  "badly"       "north"              
 [6,] "history"          "meeting"    "hashtagcrookedhillary" "cnn"         "massive"            
 [7,] "bush"             "washington" "house"                 "hashtagfitn" "every"              
 [8,] "worse"            "anything"   "defeat"                "questions"   "plan"               
 [9,] "endorsed"         "funding"    "white"                 "woman"       "expected"           
[10,] "truly"            "self"       "behind"                "thats"       "httpstcokwolibaw"  

      Topic 42       Topic 49    
 [1,] "iowa"         "president" 
 [2,] "florida"      "going"     
 [3,] "crowd"        "national"  
 [4,] "tomorrow"     "indiana"   
 [5,] "must"         "mexico"    
 [6,] "important"    "business"  
 [7,] "potus"        "close"     
 [8,] "tampa"        "protect"   
 [9,] "announcement" "government"
[10,] "complete"     "drop"    
```

So it seems that tweets not from Android tend to be rally-related or more generally PR-heavy (promoting specific hashtags, for example). 

```Rscript
# Topics positively related to android:
    topics_LDA50[,c(2,26)]
```

```Ruby
      Topic 2       Topic 26   
 [1,] "hillary"     "never"    
 [2,] "clinton"     "money"    
 [3,] "crooked"     "wonderful"
 [4,] "voter"       "millions" 
 [5,] "fraud"       "getting"  
 [6,] "poor"        "tax"      
 [7,] "sent"        "wont"     
 [8,] "problems"    "hillarys" 
 [9,] "temperament" "dollars"  
[10,] "serious"     "home" 
```
In contrast tweets from Android devices focus heavily on Hillary Clinton. Are these tweets coming more directly from Trump?
