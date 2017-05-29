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
Data obtained from the Web of Science.

### Package installation

```Rscript
# The "tm" package enables the text mining infrastructure that we will use for LDA.
    if (!require("tm")) install.packages("tm")

# The "topicmodels" package enables LDA analysis.
    if (!require("topicmodels")) install.packages("topicmodels")
    
```

### Get the data, turn into a corpus, and clean it up

```Rscript
### Load data from a URL
    data = read.csv(url("https://raw.githubusercontent.com/RFJHaans/topicmodeling/master/ASQ_AMJ_AMR_OS_SMJ.csv"))

### Create a corpus. 
    corpus = VCorpus((VectorSource(data[, "AB"])))

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
    corpusclean = tm_map(corpusclean, removeWords, c("also","based","can","data","effect",
                                                  "effects","elsevier","evidence","examine",
                                                  "find","findings","high","low","higher","lower",
                                                  "however","impact","implications","important",
                                                  "less","literature","may","model","one","paper",
                                                  "provide","research","all rights reserved",
                                                  "results","show","studies","study","two","use",
                                                  "using","rights","reserved","new","analysis","three",
                                                  "associated","firm","firms","copyright","sons","john","ltd","wiley"))

### Adding metadata from the original database
# This needs to be done because transforming things into a corpus only uses the texts.
    i = 0
    corpusclean = tm_map(corpusclean, function(x) {
      i <<- i +1
      meta(x, "id") = data[i,"ID"]
      x
    })

    i = 0
    corpusclean = tm_map(corpusclean, function(x) {
      i <<- i +1
      meta(x, "journal") = data[i,"SO"]
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
```

```Ruby
<<DocumentTermMatrix (documents: 1530, terms: 11744)>>
Non-/sparse entries: 89755/17878565
Sparsity           : 100%
Maximal term length: 30
Weighting          : term frequency (tf)
```

```Rscript
# dtms are organized with rows being documents and columns being the unique words.
# We can see here that the longest word in the corpus is 30 characters long.
# There are 1530 documents, containing 11744 unique words.

# Let's check out the sixth and seventh abstract in our data (rows in the DTM) and the 4000th to 4010th words:
inspect(dtm[6:7,4000:4010])
```

```Ruby
    Terms
Docs  facilitation facilitative facilitators facilities facility facing fact factbased factions facto
  ID6            0            0            0          0        0      1    0         0        0     0
  ID7            0            0            0          0        0      0    1         0        0     0
```

```Rscript
# Abstract six contains "facing", once. Abstract seven contains "fact" once.

# The step below is done to ensure that after removing various words, no documents are left empty 
# (LDA does not know how to deal with empty documents). 
    rowTotals = apply(dtm , 1, sum)
# This sums up the total number of words in each of the documents, e.g.:
    rowTotals[1:10]
# shows the number of words for the first ten abstracts.    
```

```Ruby
 ID1  ID2  ID3  ID4  ID5  ID6  ID7  ID8  ID9 ID10 
  40   73   85  111  103   98   97   91   82  124 
```

```Rscript


# Then, we keep only those documents where the sum of words is greater than zero.
    dtm = dtm[rowTotals> 0, ]
    dtm
# Shows no abstracts were lost due to our cleaning.      
```

```Ruby
<<DocumentTermMatrix (documents: 1530, terms: 11744)>>
Non-/sparse entries: 89755/17878565
Sparsity           : 100%
Maximal term length: 30
Weighting          : term frequency (tf)
```

### Infrequent words and frequent words
```Rscript
# Next, we will assess which words are most frequent:
    highfreq500 = findFreqTerms(dtm,500,Inf)
# This creates a vector containing words from the dtm that occur 500 or more time (100 to infinity times)
# In the top-right window, we can see that there are six words occurring more than 500 times.
# Let's see what words these are:
    highfreq500
```    

```Ruby    
[1] "knowledge"      "organizational" "organizations"  "performance"    "social"        
[6] "theory"  
```    

```Rscript
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
```  
```Ruby  
<<DocumentTermMatrix (documents: 1530, terms: 518)>>
Non-/sparse entries: 41211/751329
Sparsity           : 95%
Maximal term length: 19
Weighting          : term frequency (tf)
``` 
```Rscript
# This reduces the number of words to 518 (from 11744, so a very large reduction).
# No abstracts are removed, however. 
```  

### LDA: Running the model
```Rscript
# We first fix the random seed to for future replication.
    SEED = 123456789

# Here we define the number of topics to be estimated. I find fifty provides decent results, while much lower 
# leads to messy topics with little variation. 
# However, little theory or careful investigation went into this so be wary.
    k = 200

# We then create a variable which captures the starting time of this particular model.
    t1_LDA200 = Sys.time()
# And then we run a LDA model with 200 topics (k = 200).
# Note that the input is the dtm
    LDA200 = LDA(dtm, k = k, control = list(seed = SEED))
# The default command uses the VEM algorithm, but an alternative is Gibbs sampling (see the documentation of the topicmodels package)
# And we create a variable capturing the end time of this model.
    t2_LDA200 = Sys.time()

# We can then check the time difference to see how long the model took. 
    t2_LDA200 - t1_LDA200
```

```Ruby  
Time difference of 23.0202 mins
```

```Rscript
k = 20
# We then create a variable which captures the starting time of this particular model.
t1_LDA20 = Sys.time()
LDA20 = LDA(smalldtm, k = k, control = list(seed = SEED))
t2_LDA20 = Sys.time()

t2_LDA20 - t1_LDA20
```

```Ruby
Time difference of 11.29924 secs
```

### LDA: The output
```Rscript
# We then create a variable that captures the top ten terms assigned to the 15-topic model:
topics_LDA200 = terms(LDA200, 10)

# We can write the results of the topics to a .csv file as follows:
# write.table(topics_LDA200, file = "200_topics", sep=',',row.names = FALSE)
# This writes to the directory of the .R script, but the 'file = ' can be changed to any directory.

# And show the results:
topics_LDA200
```

```Ruby  
      Topic 1         Topic 2          Topic 3     Topic 4        Topic 5        Topic 6        Topic 7          Topic 8           Topic 9         Topic 10        Topic 11         Topic 12     
 [1,] "efforts"       "social"         "family"    "experience"   "embeddedness" "ceo"          "control"        "relationship"    "incentives"    "cognitive"     "communication"  "strategic"  
 [2,] "organizations" "exchange"       "venture"   "learning"     "network"      "ceos"         "organizational" "strategy"        "value"         "capabilities"  "processes"      "knowledge"  
 [3,] "activities"    "justice"        "control"   "performance"  "knowledge"    "support"      "attention"      "country"         "network"       "processes"     "process"        "public"     
 [4,] "work"          "perceptions"    "markets"   "prior"        "countries"    "corporate"    "organizations"  "partners"        "relationships" "control"       "coordination"   "political"  
 [5,] "behavioral"    "behavior"       "ownership" "relational"   "transfer"     "management"   "technology"     "characteristics" "formal"        "managerial"    "organizational" "private"    

       Topic 13     Topic 14        Topic 15       Topic 16         Topic 17       Topic 18              Topic 19        Topic 20         Topic 21       Topic 22     Topic 23        Topic 24     
 [1,] "market"     "events"        "team"         "change"         "knowledge"    "organizational"      "exit"          "team"           "performance"  "technology" "process"       "innovation" 
 [2,] "value"      "across"        "creativity"   "institutional"  "innovation"   "organizations"       "work"          "structure"      "social"       "knowledge"  "organizations" "corporate"  
 [3,] "growth"     "influence"     "teams"        "field"          "external"     "prior"               "analysts"      "exchange"       "diversity"    "initial"    "attention"     "network"    
 [4,] "negative"   "positive"      "individual"   "actors"         "creativity"   "search"              "boundary"      "learning"       "relationship" "learning"   "activities"    "product"    
 [5,] "will"       "focus"         "member"       "organizational" "ties"         "relationship"        "types"         "relationship"   "team"         "capacity"   "entrepreneurs" "industry"   

       Topic 25         Topic 26       Topic 27     Topic 28         Topic 29        Topic 30     Topic 31         Topic 32     Topic 33      Topic 34      Topic 35         Topic 36     
 [1,] "control"        "target"       "experience" "organizational" "knowledge"     "collective" "employees"      "network"    "ties"        "performance" "attention"      "mechanisms" 
 [2,] "organizational" "acquisition"  "role"       "units"          "innovation"    "community"  "work"           "ties"       "networks"    "exploration" "theory"         "theoretical"
 [3,] "acquisitions"   "acquisitions" "process"    "unit"           "challenges"    "management" "employee"       "networks"   "choices"     "search"      "organizations"  "different"  
 [4,] "performance"    "market"       "groups"     "strategies"     "many"          "context"    "time"           "social"     "executives"  "problem"     "organizational" "orientation"
 [5,] "managerial"     "focal"        "knowledge"  "relationship"   "form"          "knowledge"  "related"        "structure"  "make"        "information" "processes"      "strategies" 

       Topic 37     Topic 38           Topic 39        Topic 40       Topic 41         Topic 42         Topic 43         Topic 44         Topic 45      Topic 46         Topic 47         
 [1,] "media"      "employee"         "performance"   "social"       "leadership"     "events"         "mechanisms"     "organizational" "integration" "knowledge"      "strategy"       
 [2,] "voice"      "entrepreneurship" "relationships" "performance"  "behaviors"      "organizational" "organizations"  "theory"         "capital"     "transfer"       "fit"            
 [3,] "product"    "knowledge"        "ceo"           "justice"      "leaders"        "work"           "theory"         "routines"       "boundaries"  "network"        "past"           
 [4,] "managerial" "events"           "influence"     "diversity"    "work"           "framework"      "agency"         "business"       "process"     "boundary"       "innovation"     
 [5,] "control"    "behavior"         "types"         "corporate"    "performance"    "creative"       "organizational" "capabilities"   "innovation"  "organizational" "develop"        

       Topic 48         Topic 49        Topic 50       Topic 51        Topic 52        Topic 53      Topic 54         Topic 55         Topic 56         Topic 57         Topic 58          
 [1,] "learning"       "innovation"    "market"       "performance"   "ties"          "networks"    "identity"       "organizational" "social"         "complexity"     "uncertainty"     
 [2,] "organizational" "technology"    "governance"   "product"       "logics"        "network"     "identities"     "risk"           "theory"         "task"           "different"       
 [3,] "value"          "network"       "capabilities" "strategic"     "building"      "groups"      "organizational" "social"         "models"         "organizational" "choice"          
 [4,] "theory"         "organizations" "companies"    "development"   "market"        "group"       "work"           "making"         "organizations"  "degree"         "governance"      
 [5,] "processes"      "networks"      "executives"   "case"          "categories"    "ties"        "individuals"    "perspective"    "institutional"  "complex"        "structure"       

       Topic 59         Topic 60      Topic 61        Topic 62     Topic 63          Topic 64        Topic 65        Topic 66       Topic 67        Topic 68      Topic 69      Topic 70    
 [1,] "strategy"       "feedback"    "entry"         "power"      "team"            "institutional" "different"     "performance"  "performance"   "activities"  "performance" "work"      
 [2,] "affect"         "performance" "industry"      "source"     "entrepreneurial" "local"         "argue"         "coordination" "social"        "performance" "leader"      "change"    
 [3,] "management"     "creative"    "technologies"  "ownership"  "teams"           "logics"        "performance"   "team"         "capabilities"  "learning"    "negative"    "action"    
 [4,] "top"            "workers"     "power"         "theory"     "changes"         "search"        "among"         "teams"        "quality"       "activity"    "actions"     "mechanisms"
 [5,] "role"           "internal"    "business"      "management" "products"        "investment"    "private"       "management"   "status"        "patterns"    "theory"      "practices" 

       Topic 71         Topic 72       Topic 73         Topic 74        Topic 75      Topic 76         Topic 77      Topic 78      Topic 79        Topic 80        Topic 81       Topic 82         
 [1,] "information"    "search"       "voice"          "institutional" "women"       "organizations"  "decision"    "turnover"    "design"        "communication" "job"          "pay"            
 [2,] "social"         "likelihood"   "workplace"      "institutions"  "men"         "organizational" "making"      "performance" "products"      "team"          "satisfaction" "managers"       
 [3,] "status"         "engagement"   "employees"      "business"      "gender"      "success"        "ethical"     "job"         "technological" "members"       "relationship" "corporate"      
 [4,] "within"         "joint"        "outcomes"       "countries"     "social"      "framework"      "group"       "employees"   "product"       "managers"      "turnover"     "social"         
 [5,] "individuals"    "models"       "identification" "ownership"     "differences" "strategy"       "process"     "theory"      "industry"      "teams"         "individual"   "discuss"        

       Topic 83           Topic 84      Topic 85         Topic 86         Topic 87     Topic 88      Topic 89     Topic 90        Topic 91     Topic 92        Topic 93      Topic 94         
 [1,] "logic"            "employees"   "organizational" "institutional"  "alliances"  "market"      "industry"   "market"        "directors"  "entrepreneurs" "team"        "theory"         
 [2,] "field"            "performance" "employee"       "differences"    "knowledge"  "ties"        "corporate"  "product"       "board"      "information"   "teams"       "practice"       
 [3,] "organizations"    "likely"      "employees"      "environments"   "governance" "value"       "ventures"   "complementary" "boards"     "product"       "members"     "characteristics"
 [4,] "social"           "negative"    "individuals"    "theory"         "reputation" "exit"        "venture"    "knowledge"     "corporate"  "search"        "time"        "process"        
 [5,] "logics"           "job"         "leadership"     "legitimacy"     "alliance"   "form"        "reputation" "exploration"   "governance" "actions"       "motivation"  "organizational" 

       Topic 95         Topic 96        Topic 97              Topic 98       Topic 99         Topic 100     Topic 101   Topic 102        Topic 103       Topic 104     Topic 105     
 [1,] "organizational" "creative"      "learning"            "decision"     "organizational" "ceos"        "parties"   "corporate"      "capability"    "projects"    "work"        
 [2,] "theory"         "decisions"     "foreign"             "makers"       "work"           "ceo"         "third"     "organizational" "capabilities"  "within"      "interactions"
 [3,] "executives"     "managers"      "entry"               "performance"  "trust"          "will"        "positive"  "managers"       "dynamic"       "theory"      "online"      
 [4,] "employee"       "strategic"     "industry"            "information"  "institutional"  "performance" "perceived" "attention"      "development"   "investments" "team"        
 [5,] "units"          "relational"    "interorganizational" "strategic"    "peers"          "theory"      "social"    "industries"     "resources"     "economic"    "coordination"

       Topic 106         Topic 107        Topic 108         Topic 109     Topic 110     Topic 111          Topic 112        Topic 113        Topic 114       Topic 115    Topic 116        
 [1,] "performance"     "logics"         "performance"     "networks"    "performance" "industry"         "theory"         "attention"      "women"         "innovation" "work"           
 [2,] "costs"           "institutional"  "managers"        "network"     "status"      "behavioral"       "management"     "organizational" "gender"        "industry"   "framework"      
 [3,] "diversification" "organizational" "among"           "social"      "groups"      "learning"         "theories"       "evolution"      "men"           "business"   "dimensions"     
 [4,] "search"          "different"      "decisions"       "entry"       "group"       "subsequent"       "framework"      "capabilities"   "employees"     "capital"    "within"         
 [5,] "market"          "outcomes"       "projects"        "structure"   "work"        "acquisition"      "approach"       "management"     "psychological" "target"     "understanding"  

       Topic 117         Topic 118        Topic 119        Topic 120    Topic 121        Topic 122        Topic 123        Topic 124        Topic 125       Topic 126             Topic 127    
 [1,] "diversification" "development"    "organizations"  "alliance"   "status"         "status"         "decisions"      "knowledge"      "institutional" "exchange"            "csr"        
 [2,] "international"   "organizational" "community"      "alliances"  "performance"    "market"         "regulatory"     "performance"    "capabilities"  "partners"            "ceos"       
 [3,] "relationship"    "justice"        "relationships"  "partners"   "negative"       "positive"       "institutional"  "capabilities"   "reputation"    "relationships"       "political"  
 [4,] "financial"       "routines"       "organizational" "prior"      "individuals"    "organization"   "differences"    "external"       "complexity"    "social"              "corporate"  
 [5,] "product"         "time"           "social"         "within"     "social"         "reputation"     "foreign"        "learning"       "decision"      "prior"               "stakeholder"

       Topic 128        Topic 129         Topic 130        Topic 131       Topic 132     Topic 133      Topic 134     Topic 135   Topic 136      Topic 137        Topic 138   Topic 139     
 [1,] "learning"       "conflict"        "performance"    "social"        "performance" "capabilities" "innovation"  "target"    "family"       "capital"        "alliance"  "ideas"       
 [2,] "organizations"  "focus"           "decision"       "women"         "approaches"  "market"       "performance" "strategy"  "strategic"    "human"          "alliances" "diversity"   
 [3,] "organizational" "experience"      "makers"         "men"           "resources"   "markets"      "financial"   "first"     "behavioral"   "categories"     "partners"  "investments" 
 [4,] "collective"     "regulatory"      "context"        "organization"  "competitive" "likely"       "knowledge"   "corporate" "management"   "market"         "learning"  "group"       
 [5,] "status"         "process"         "employees"      "interactions"  "empirical"   "costs"        "changes"     "type"      "strategy"     "employee"       "value"     "creative"    

       Topic 140       Topic 141        Topic 142     Topic 143       Topic 144         Topic 145       Topic 146       Topic 147     Topic 148        Topic 149        Topic 150      
 [1,] "work"          "corporate"      "work"        "groups"        "teams"           "behavioral"    "across"        "performance" "ethical"        "acquisition"    "focus"        
 [2,] "control"       "governance"     "support"     "power"         "services"        "family"        "external"      "members"     "moral"          "growth"         "international"
 [3,] "system"        "stakeholders"   "develop"     "financial"     "strategic"       "superior"      "collaboration" "collective"  "organizations"  "risk"           "ceos"         
 [4,] "resources"     "organizational" "cognitive"   "group"         "diverse"         "strategy"      "practices"     "family"      "influence"      "market"         "performance"  
 [5,] "organizations" "framework"      "role"        "business"      "diversity"       "performance"   "levels"        "individual"  "leadership"     "test"           "early"        

       Topic 151         Topic 152     Topic 153       Topic 154        Topic 155      Topic 156        Topic 157       Topic 158     Topic 159     Topic 160        Topic 161     Topic 162     
 [1,] "analysts"        "social"      "job"           "cultural"       "field"        "knowledge"      "opportunities" "business"    "options"     "technology"     "types"       "social"      
 [2,] "diversification" "individuals" "search"        "organizational" "theory"       "management"     "process"       "diversity"   "performance" "learning"       "positive"    "markets"     
 [3,] "competitive"     "role"        "jobs"          "organization"   "innovations"  "learning"       "sources"       "positive"    "technology"  "organizational" "concept"     "online"      
 [4,] "future"          "influence"   "performance"   "practices"      "capabilities" "organizational" "within"        "core"        "logic"       "experiences"    "better"      "behaviors"   
 [5,] "status"          "managers"    "organizations" "organizations"  "capital"      "routines"       "external"      "managerial"  "markets"     "knowledge"      "used"        "community"   

       Topic 163      Topic 164      Topic 165      Topic 166       Topic 167     Topic 168    Topic 169          Topic 170        Topic 171        Topic 172       Topic 173        Topic 174    
 [1,] "development"  "performance"  "ceo"          "decisions"     "values"      "jobs"       "institutional"    "fit"            "organizational" "network"       "performance"    "resource"   
 [2,] "power"        "social"       "compensation" "time"          "performance" "dependence" "entrepreneurship" "performance"    "adoption"       "collaboration" "organizational" "market"     
 [3,] "technologies" "companies"    "directors"    "experience"    "work"        "power"      "organizational"   "services"       "practice"       "actors"        "organizations"  "performance"
 [4,] "positive"     "economic"     "outside"      "influence"     "management"  "job"        "innovation"       "institutional"  "status"         "knowledge"     "individuals"    "governance" 
 [5,] "address"      "relationship" "risk"         "communication" "identity"    "theory"     "analysts"         "products"       "organizations"  "social"        "innovation"     "political"  

Topic 175       Topic 176     Topic 177       Topic 178        Topic 179     Topic 180     Topic 181       Topic 182       Topic 183        Topic 184     Topic 185         Topic 186       
 [1,] "environmental" "decision"    "activities"    "organizational" "benefits"    "leadership"  "resources"     "team"          "strategic"      "business"    "employees"       "organizational"
 [2,] "teams"         "knowledge"   "dependence"    "managers"       "strategy"    "leaders"     "institutional" "creative"      "actions"        "systems"     "behaviors"       "organizations" 
 [3,] "team"          "decisions"   "investment"    "identification" "context"     "theory"      "market"        "innovation"    "network"        "existing"    "opportunities"   "forms"         
 [4,] "performance"   "making"      "communication" "members"        "mechanisms"  "behavior"    "complementary" "development"   "actors"         "relational"  "opportunity"     "practices"     
 [5,] "information"   "foreign"     "social"        "social"         "performance" "leader"      "context"       "knowledge"     "organizational" "investment"  "voice"           "organization"  

       Topic 187       Topic 188        Topic 189        Topic 190     Topic 191     Topic 192       Topic 193      Topic 194        Topic 195        Topic 196      Topic 197        Topic 198    
 [1,] "relationship"  "organizational" "change"         "value"       "market"      "work"          "performance"  "identity"       "team"           "influence"    "groups"         "group"      
 [2,] "political"     "innovation"     "strategic"      "performance" "competitive" "ties"          "business"     "organizational" "members"        "political"    "online"         "routines"   
 [3,] "psychological" "technology"     "organizational" "competitive" "industry"    "relationships" "unit"         "identification" "among"          "association"  "routines"       "ties"       
 [4,] "need"          "technological"  "develop"        "strategy"    "advantage"   "strategies"    "leadership"   "social"         "performance"    "performance"  "competition"    "identity"   
 [5,] "professional"  "will"           "distinct"       "advantage"   "resource"    "outcomes"      "team"         "organizations"  "teams"          "public"       "innovation"     "groups"     

       Topic 199       Topic 200    
 [1,] "resources"     "knowledge"  
 [2,] "resource"      "field"      
 [3,] "portfolio"     "practice"   
 [4,] "value"         "personal"   
 [5,] "communication" "differences"
```

```Rscript
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
majortopics$topic = sub("^$", 0, majortopics$topic)
colnames(majortopics) = "topic" 
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

```

### Plotting topic usage across journals and over time
We will use the most important topics for each tweet to see if it can predict whether or not the tweet was sent from an Android device. 
See, for example: https://www.theatlantic.com/technology/archive/2017/03/trump-android-tweets/520869/
This would suggest that "real" Trump tweets may be coming from an Android device, and differing topic usage across platforms may indicate that the tweets are coming from different sources (Trump, using Android, versus his team, using non-Android devices). 

We estimate a logit model to predict this outcome, with dummies for every topic. 
```Rscript
# We cross-tabulate journals and highest loading topics
crosstabtable = table(highest)
crosstabtable
```
```Ruby 
                                  maintopic
data$SO                             1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20
  ACADEMY OF MANAGEMENT JOURNAL     1  3  1  0  3  4  3  0  1  1  1  0  2  0  4  6  0  0  1  1
  ACADEMY OF MANAGEMENT REVIEW      2  1  0  0  1  0  0  0  0  4  0  0  0  1  0  0  0  1  2  1
  ADMINISTRATIVE SCIENCE QUARTERLY  0  1  1  0  2  3  0  0  0  0  0  0  0  1  0  0  1  2  0  0
  ORGANIZATION SCIENCE              4  4  2  4  2  0  4  1  2  3  5  3  0  1  0  4  5  4  3  2
  STRATEGIC MANAGEMENT JOURNAL      0  0  6  3  2  9  1  6  5  5  2  2  5  3  1  2  2  1  1  0
                                  maintopic
data$SO                            21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40
  ACADEMY OF MANAGEMENT JOURNAL     4  0  2  2  2  0  1  2  0  3  7  0  2  0  2  7  3  0  0  2
  ACADEMY OF MANAGEMENT REVIEW      0  0  1  0  0  0  0  0  2  1  0  0  1  0  1  1  0  2  1  1
  ADMINISTRATIVE SCIENCE QUARTERLY  0  0  0  0  1  2  1  1  0  0  1  0  2  0  2  0  0  0  0  0
  ORGANIZATION SCIENCE              1  3  5  2  1  0  1  2  7  2  5  9  5  3  4  2  1  2  2  2
  STRATEGIC MANAGEMENT JOURNAL      3  3  1  6  2  6  1  2  1  1  0  3  2  4  2  1  0  3  3  4
                                  maintopic
data$SO                            41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60
  ACADEMY OF MANAGEMENT JOURNAL     5  3  5  2  1  2  0  1  0  0  1  2  3  5  0  2  0  0  2  3
  ACADEMY OF MANAGEMENT REVIEW      1  0  0  0  0  0  0  1  0  0  0  1  1  5  0  6  2  1  0  0
  ADMINISTRATIVE SCIENCE QUARTERLY  0  0  1  0  2  0  0  1  1  2  0  0  0  0  1  0  0  0  0  1
  ORGANIZATION SCIENCE              1  4  3  3  3  3  4  3  2  3  4  3  2  3  5  0  1  1  2  1
  STRATEGIC MANAGEMENT JOURNAL      1  1  1  2  1  2  4  2  3  2  6  1  1  0  2  0  0  6  3  1
                                  maintopic
data$SO                            61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80
  ACADEMY OF MANAGEMENT JOURNAL     2  2  2  2  3  4  2  1  7  3  1  1  2  3  3  0  3  6  0  1
  ACADEMY OF MANAGEMENT REVIEW      0  2  1  0  1  0  1  1  0  1  1  0  1  0  0  2  1  2  1  0
  ADMINISTRATIVE SCIENCE QUARTERLY  0  0  1  1  0  0  3  0  0  0  0  2  0  1  1  0  1  1  0  0
  ORGANIZATION SCIENCE              2  1  1  1  2  4  0  6  1  2  4  2  3  0  2  3  4  3  2  4
  STRATEGIC MANAGEMENT JOURNAL      3  3  2  2  4  3  4  2  1  3  2  1  0  3  0  2  0  1  5  0
                                  maintopic
data$SO                            81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99
  ACADEMY OF MANAGEMENT JOURNAL     6  0  5  4  0  0  0  1  1  1  2  2  3  0  0  3  2  1  2
  ACADEMY OF MANAGEMENT REVIEW      0  0  5  0  1  3  0  1  0  0  0  1  1  4  1  1  0  1  1
  ADMINISTRATIVE SCIENCE QUARTERLY  0  0  0  0  0  0  0  1  0  0  1  0  0  0  1  0  0  0  0
  ORGANIZATION SCIENCE              1  3  0  1  2  1  2  1  2  4  3  2  2  2  3  2  4  2  2
  STRATEGIC MANAGEMENT JOURNAL      1  4  0  3  1  4  3  0  5  1  4  1  1  1  1  1  6  7  0
                                  maintopic
data$SO                            100 101 102 103 104 105 106 107 108 109 110 111 112 113 114
  ACADEMY OF MANAGEMENT JOURNAL      2   1   2   0   2   0   1   2   1   2   2   2   1   0   1
  ACADEMY OF MANAGEMENT REVIEW       0   1   0   0   0   1   1   0   0   0   0   0   5   2   0
  ADMINISTRATIVE SCIENCE QUARTERLY   5   0   0   0   0   0   0   1   0   1   0   1   0   0   1
  ORGANIZATION SCIENCE               2   3   3   3   5   3   1   3   2   1   5   0   1   3   1
  STRATEGIC MANAGEMENT JOURNAL       8   0   2   3   2   1   5   1   1   1   2   3   1   2   2
                                  maintopic
data$SO                            115 116 117 118 119 120 121 122 123 124 125 126 127 128 129
  ACADEMY OF MANAGEMENT JOURNAL      1   0   1   3   3   1   3   1   0   2   1   2   0   0   2
  ACADEMY OF MANAGEMENT REVIEW       0   2   0   1   1   0   0   1   0   0   1   0   0   2   1
  ADMINISTRATIVE SCIENCE QUARTERLY   1   0   0   2   3   0   0   3   2   0   0   0   1   0   0
  ORGANIZATION SCIENCE               0   2   4   1   0   3   4   2   6   1   1   2   1   5   1
  STRATEGIC MANAGEMENT JOURNAL       4   0   6   1   1   3   0   0   1   4   3   1   4   0   4
                                  maintopic
data$SO                            130 131 132 133 134 135 136 137 138 139 140 141 142 143 144
  ACADEMY OF MANAGEMENT JOURNAL      3   0   2   0   0   1   1   1   1   0   0   1   2   0   1
  ACADEMY OF MANAGEMENT REVIEW       0   0   0   0   0   0   0   2   0   0   1   2   2   1   0
  ADMINISTRATIVE SCIENCE QUARTERLY   0   0   0   0   0   2   0   0   0   2   0   0   0   1   0
  ORGANIZATION SCIENCE               2   4   3   0   2   0   1   5   3   3   1   2   2   2   4
  STRATEGIC MANAGEMENT JOURNAL       1   0   7  10   8   2   9   1   5   5   1   2   1   2   1
                                  maintopic
data$SO                            145 146 147 148 149 150 151 152 153 154 155 156 157 158 159
  ACADEMY OF MANAGEMENT JOURNAL      0   1   1   4   1   1   3   2   3   1   0   1   2   1   1
  ACADEMY OF MANAGEMENT REVIEW       0   0   0   1   0   0   1   1   0   2   1   0   0   1   1
  ADMINISTRATIVE SCIENCE QUARTERLY   0   0   0   0   1   0   0   1   0   0   1   0   0   0   0
  ORGANIZATION SCIENCE               3   7   3   2   3   1   1   3   3   7   0   5   3   1   1
  STRATEGIC MANAGEMENT JOURNAL       3   2   2   2   3   3   3   2   0   1   4   1   2   4   1
                                  maintopic
data$SO                            160 161 162 163 164 165 166 167 168 169 170 171 172 173 174
  ACADEMY OF MANAGEMENT JOURNAL      2   2   0   2   3   3   3   1   2   0   0   3   3   0   1
  ACADEMY OF MANAGEMENT REVIEW       0   0   1   0   0   0   1   1   2   1   0   1   0   0   0
  ADMINISTRATIVE SCIENCE QUARTERLY   1   2   0   1   0   1   1   2   3   1   0   1   0   0   0
  ORGANIZATION SCIENCE               3   1   3   2   2   4   2   1   2   2   3   4   3   6   0
  STRATEGIC MANAGEMENT JOURNAL       1   1   1   3   1   8   0   0   2   3   2   1   0   0  10
                                  maintopic
data$SO                            175 176 177 178 179 180 181 182 183 184 185 186 187 188 189
  ACADEMY OF MANAGEMENT JOURNAL      2   2   2   2   1   4   1   1   1   0   3   3   2   1   2
  ACADEMY OF MANAGEMENT REVIEW       1   0   0   0   1   1   0   0   0   2   1   0   1   1   1
  ADMINISTRATIVE SCIENCE QUARTERLY   0   0   0   2   0   0   0   1   0   0   0   0   1   2   0
  ORGANIZATION SCIENCE               1   1   1   1   3   1   2   1   2   2   3   4   1   3   3
  STRATEGIC MANAGEMENT JOURNAL       0   0   5   0   2   1   8   2   3   2   1   1   0   0   2
                                  maintopic
data$SO                            190 191 192 193 194 195 196 197 198 199 200
  ACADEMY OF MANAGEMENT JOURNAL      0   3   2   4   0   3   0   2   1   1   2
  ACADEMY OF MANAGEMENT REVIEW       2   0   1   0   5   0   1   0   0   0   2
  ADMINISTRATIVE SCIENCE QUARTERLY   0   0   1   0   0   1   0   0   1   0   0
  ORGANIZATION SCIENCE               1   3   2   1   2   1   2   4   2   1   4
  STRATEGIC MANAGEMENT JOURNAL       9   6   0   5   1   2   4   1   0   6   2
```

```Rscript
# And create a barplot (first line) with ticks at every X value (second line)
   barplot(crosstabtable,legend.text =  c("AMJ", "AMR","ASQ","OS","SMJ"),col = c("gray0","gray20","gray60","gray80","gray100"),            axisnames=FALSE)
   axis(3,at=xpos,labels=seq(1,200,by=1))
```
![](https://raw.githubusercontent.com/RFJHaans/topicmodeling/master/alljournals.png)
```Rscript
# We can also check only for the SMJ, for example.
    barplot(crosstabtable["ACADEMY OF MANAGEMENT JOURNAL",], axisnames=FALSE)
    axis(3,at=xpos,labels=seq(1,200,by=1))
```
![](https://raw.githubusercontent.com/RFJHaans/topicmodeling/master/AMJ.png)
```Rscript
# We can take a similar approach to look at trends over time.
    highest_year = as.data.frame(data$PY)
    highest_year$maintopic = topics(LDA200, k = 1)

    crosstabtable_year = table(highest_year)
    barplot(crosstabtable_year,legend.text =  c("2011", "2012","2013","2014","2015"),col =       c("gray0","gray20","gray60","gray80","gray100"), axisnames=FALSE)
    axis(3,at=xpos,labels=seq(1,200,by=1))
```
![](https://raw.githubusercontent.com/RFJHaans/topicmodeling/master/years.png)
```Rscript
    barplot(crosstabtable[1,], axisnames=FALSE)
    axis(3,at=xpos,labels=seq(1,200,by=1))
```
![](https://raw.githubusercontent.com/RFJHaans/topicmodeling/master/2011.png)

