#########################################
### General notes
#########################################
# Code tested and written for R version 3.4, tm package version 0.7-1, topicmodels package version 0.2-6.
# Code prepared on May 22, 2017 by Richard Haans (haans@rsm.nl).

# Data obtained from the Web of Science.

#########################################
### Package installation
#########################################
# The "tm" package enables the text mining infrastructure that we will use for LDA.
if (!require("tm")) install.packages("tm")
# The "topicmodels" package enables LDA analysis.
if (!require("topicmodels")) install.packages("topicmodels")


### Load the output of the 200-topic model (we cannot run it during the workshop due to time constraints). 
load(url("https://github.com/RFJHaans/topicmodeling/blob/master/LDA200.RData?raw=true"))

### And open the R code of this workshop (needs to be copy-pasted into an R script after loading):
url.show("https://raw.githubusercontent.com/RFJHaans/topicmodeling/master/2017%20AoM%20LDA%20Workshop%20-%20abstracts.R")

#########################################
### Get the data, turn into a corpus, and clean it up
#########################################
# Load data from a URL
data = read.csv(url("https://raw.githubusercontent.com/RFJHaans/topicmodeling/master/ASQ_AMJ_AMR_OS_SMJ.csv"))

# Create a corpus. 
corpus = VCorpus((VectorSource(data[, "AB"])))
# The AB column contains the abstracts.

# Basic cleaning (step-wise)
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

# i	me	my	myself	we	our	ours	ourselves	you	your	yours	yourself	yourselves	he	him	his	himself	
# she	her	hers	herself	it	its	itself	they	them	their	theirs	themselves	what	which	who	whom	this
# that	these	those	am	is	are	was	were	be	been	being	have	has	had	having	do	does	did	doing	would	should
# could	ought	i'm	you're	he's	she's	it's	we're	they're	i've	you've	we've	they've	i'd	you'd	he'd	she'd	we'd
# they'd	i'll	you'll	he'll	she'll	we'll	they'll	isn't	aren't	wasn't	weren't	hasn't	haven't	hadn't	doesn't	
# don't	didn't	won't	wouldn't	shan't	shouldn't	can't	cannot	couldn't	mustn't	let's	that's	who's	what's	here's
# there's	when's	where's	why's	how's	a	an	the	and	but	if	or	because	as	until	while	of	at	by	for	with	about	
# against	between	into	through	during	before	after	above	below	to	from	up	down	in	out	on	off	over	under	again
# further	then	once	here	there	when	where	why	how	all	any	both	each	few	more	most	other	some	such	no	nor	
# not	only	own	same	so	than	too	very

# 5) And strip whitespace. 
corpusclean = tm_map(corpusclean , stripWhitespace)

# See the help of getTransformations for more possibilities, such as stemming. 

# To speed up the computation process for this tutorial, I have selected some choice words that were very common:
# We update the corpusclean corpus by removing these words. 
# Note that I remove firm and firms, as they otherwise seem to appear in nearly every topic.
corpusclean = tm_map(corpusclean, removeWords, c("also","based","can","data","effect",
                                                  "effects","elsevier","evidence","examine",
                                                  "find","findings","high","low","higher","lower",
                                                  "however","impact","implications","important",
                                                  "less","literature","may","model","one","paper",
                                                  "provide","research","all rights reserved",
                                                  "results","show","studies","study","two","use",
                                                  "using","rights","reserved","new","analysis","three",
                                                  "associated","firm","firms","copyright","sons","john","ltd","wiley"))

## Adding metadata from the original database
# This needs to be done because transforming things into a corpus only uses the texts from the abstracts.
i = 0
corpusclean = tm_map(corpusclean, function(x) {
  i <<- i +1
  meta(x, "id") = as.character(data[i,"ID"])
  x
})

i = 0
corpusclean = tm_map(corpusclean, function(x) {
  i <<- i +1
  meta(x, "journal") = as.character(data[i,"SO"])
  x
})

# The above is a loop that goes through all files ("i") in the corpus
# and then maps the information of the metadata dataframe 
# (the "ID" column, et cetera) to a new piece of metadata in the corpus
# which we also call "id", et cetera.

# This enables making selections of the corpus based on metadata now.
# Let's say we want to only look at articles from the AMJ, then we do the following:
keep = meta(corpusclean, "journal") == "ACADEMY OF MANAGEMENT JOURNAL"
corpus.AMJ = corpusclean[keep]

# We then convert the corpus to a "Document-term-matrix" (dtm)
dtm =DocumentTermMatrix(corpusclean)  
dtm
# dtms are organized with rows being documents and columns being the unique words.
# We can see here that the longest word in the corpus is 30 characters long.
# There are 1530 documents, containing 11744 unique words.

# Let's check out the sixth and seventh abstract in our data (rows in the DTM) and the 4000th to 4010th words:
inspect(dtm[6:7,4000:4010])
# Abstract six contains "facing", once. Abstract seven contains "fact" once.


# The step below is done to ensure that after removing various words, no documents are left empty 
# (LDA does not know how to deal with empty documents). 
rowTotals = apply(dtm , 1, sum)
# This sums up the total number of words in each of the documents, e.g.:
rowTotals[1:10]
# shows the number of words for the first ten abstracts

# Then, we keep only those documents where the sum of words is greater than zero.
dtm   = dtm[rowTotals> 0, ]
dtm
# Shows no abstracts were lost due to our cleaning.


#########################################
### Infrequent words and frequent words
#########################################
# Next, we will assess which words are most frequent:
highfreq500 = findFreqTerms(dtm,500,Inf)
# This creates a vector containing words from the dtm that occur 500 or more time (500 to infinity times)
# In the top-right window, we can see that there are six words occurring more than 500 times.
# Let's see what words these are:
highfreq500

# We can create a smaller dtm that makes the following two selections on the words in the corpus:
# This greatly saves on computing time, but infrequent words may also provide valuable information,
# so one needs to be careful when selecting cut-off values.
# 1) Keep only those words that occur more than 50 times.
minoccur = 50
# 2) Keep only those words that occur in at least 10 of the documents. 
mindocs = 10
# Note that this is completed on the corpus, not the DTM. 
smalldtm = DocumentTermMatrix(corpusclean, control=list(dictionary = findFreqTerms(dtm,minoccur,Inf), 
                                                                  bounds = list(global = c(mindocs,Inf))))

rowTotals = apply(smalldtm , 1, sum)
smalldtm   = smalldtm[rowTotals> 0, ]
smalldtm
# This reduces the number of words to 518 (from 11744, so a very large reduction).
# No abstracts are removed, however. 


#########################################
### LDA: Running the model
#########################################
# We first fix the random seed for future replication.
SEED = 123456789

# Here we define the number of topics to be estimated. I find two-hundred provides decent results.
# However, little theory or thought went into this so be wary.
k = 200

# We then create a variable which captures the starting time of this particular model.
t1_LDA200 = Sys.time()
# And then we run a LDA model with 200 topics (k = 200).

# Note that the input is the smaller dtm
LDA200 = LDA(smalldtm, k = k, control = list(seed = SEED))
# The default command uses the VEM algorithm, but an alternative is Gibbs sampling (see the documentation of the topicmodels package)
# And we create a variable capturing the end time of this model.
t2_LDA200 = Sys.time()

# We can then check the time difference to see how long the model took. 
t2_LDA200 - t1_LDA200
# About 23 minutes.


# We can also run a model with fewer topics to compare.
k = 20
# We then create a variable which captures the starting time of this particular model.
t1_LDA20 = Sys.time()
LDA20 = LDA(smalldtm, k = k, control = list(seed = SEED))
t2_LDA20 = Sys.time()

t2_LDA20 - t1_LDA20
# 11.29 seconds

#########################################
### LDA: The output
#########################################
# We then create a variable that captures the top ten terms assigned to the 15-topic model:
topics_LDA200 = terms(LDA200, 10)
# And show the results:
topics_LDA200

topics_LDA20 = terms(LDA20, 10)
# And show the results:
topics_LDA20

# We can write the results of the topics to a .csv file as follows:
# write.table(topics_LDA200, file = "200_topics", sep=',',row.names = FALSE)
# This writes to the directory of the .R script, but the 'file = ' can be changed to any directory.

# How to show term weights:
word_assignments200 <- t(posterior(LDA200)[["terms"]])
word_assignments200[1:10,1:10]



# Let's now create a file containing the topic loadings for all articles:
gammaDF_LDA200 = as.data.frame(LDA200@gamma) 
# This creates a dataframe containing for every row the articles and for every column the per-topic loading.
gammaDF_LDA200$ID = smalldtm$dimnames$Docs
# We add the ID from the metadata for merging with the metadata file. Of course
# any other type of data can be added.


# If we are not necessarily interested in using the full range of topic loadings,
# but only in keeping those loadings that exceed a certain threshold, 
# then we can use the code below:
majortopics = topics(LDA200, threshold = 0.3)
majortopics = as.data.frame(vapply(majortopics, 
       paste, collapse = ", ", character(1L)))
colnames(majortopics) = "topic" 
majortopics$topic = sub("^$", 0, majortopics$topic)

# Here, we state that we want to show all topics that load greater than 0.3, per paper.
# Of course, the higher the threshold, the fewer topics will be selected per paper.
# The flattening (the second and third line) is done to clean this column up (from e.g. "c(1,5,7)" to "1,5,7")
# The fourth line replaces those without a topic with the value zero.
# The last line renames the column.

# Some abstracts may have no topics assigned to them.
# NOTE: It will report the topics in a sequential manner - the first topic in this list is not
# necessarily the most important topic. 


# We can also select the highest loading topic for every paper by changing the threshold-subcommand
# to k = (k refers to the number of highest loading topics per paper):
highest = as.data.frame(data$SO)
# I first make a column containing the journal, since we're going to do some follow-up checks on this dataframe. 
highest$maintopic = topics(LDA200, k = 1)
# I then add the highest loading topic of each abstract. We can do this because the order of the data is identical. 
# Otherwise, we'd need to match the two using the ID variable (e.g. if some abstracts had been removed due to cleaning).

# We cross-tabulate journals and highest loading topics
crosstabtable = table(highest)

# The following topics are most distinctive for each journal:
# AMJ: Topic 69  --> performance, leader, negative, actions, theory
# AMR: Topic 56  --> social, theory, models, organizations, institutional
# ASQ: Topic 100 --> ceos, ceo, will, performance, theory
# OS:  Topic 32  --> network, ties, networks, social, structure
# SMJ: Topic 133 --> capabilities, market, markets, likely, costs

# And create a barplot (first line) with ticks at every X value (second line)
bar1 <- barplot(crosstabtable,legend.text =  c("AMJ", "AMR","ASQ","OS","SMJ"),col = c("gray0","gray20","gray60","gray80","gray100"), axisnames=FALSE)
axis(3,at=bar1,labels=seq(1,200,by=1))

# We can also check only for the SMJ, for example.
bar2 <-barplot(crosstabtable["ACADEMY OF MANAGEMENT JOURNAL",], axisnames=FALSE)
axis(3,at=bar2,labels=seq(1,200,by=1))

# We can take a similar approach to look at trends over time.
highest_year = as.data.frame(data$PY)
highest_year$maintopic = topics(LDA200, k = 1)

crosstabtable_year = table(highest_year)
bar3 <-barplot(crosstabtable_year,legend.text =  c("2011", "2012","2013","2014","2015"),col = c("gray0","gray20","gray60","gray80","gray100"), axisnames=FALSE)
axis(3,at=bar3,labels=seq(1,200,by=1))

bar4 <-barplot(crosstabtable[1,], axisnames=FALSE)
axis(3,at=bar4,labels=seq(1,200,by=1))




