First time setup in R
=====================
In order to follow the code developed for the workshop (shown in full below under Workshop example), two pieces of software need to be installed beforehand. The first is R, a free software environment for statistical computing and graphics. The second is RStudio, which is a graphical user interface that goes 'over' R, making it more user friendly. It is adamant that R is installed first, and RStudio second.

Before running the code shown below, install R on your system by going to the following page:
https://cran.r-project.org/
Here, OS-specific versions of R can be found. For example, by clicking <a href="https://cran.r-project.org/bin/windows/base/">here</a>, you can download the executable for Windows. For Mac OS X, the install file can be found <a href="https://cran.r-project.org/bin/macosx/">here</a>. Installation using the default settings should do the trick.

Then, after the installation of R is complete, navigate to the following page:
https://www.rstudio.com/
You can download the free version of RStudio on <a href="https://www.rstudio.com/products/rstudio/download/">this page</a>. Again, the default settings should do the trick.

Then, after these steps are completed, it is advisable to run the following two lines of code in RStudio before coming to the workshop. 
```Rscript
# The "tm" package enables the text mining infrastructure that we will use for LDA.
    if (!require("tm")) install.packages("tm")

# The "topicmodels" package enables LDA analysis.
    if (!require("topicmodels")) install.packages("topicmodels")

# The "LDAVis" package enables visualization from the LDA analysis.
    if (!require("LDAVis")) install.packages("LDAVis")
    
# The "igraph" package enables creation of networks.
    if (!require("igraph")) install.packages("igraph")  
```

These will install the core packages that we will use in the workshop, and their installation may take some time on the standard conference internet connection. After this is done, you're all set to participate in the workshop! It is also possible to run the code shown below at home beforehand, but note that the actual topic model takes a LONG time to finish on most PCs. 

You can install packages by entering them to your script (you can start a new script on Windows via "Shift+Ctrl+N" or by navigating to "File" --> "New File" --> "R Script". You can run code by selecting the code and pressing "Ctrl + Enter" or the "Run" button at the top of the script window. Packages can also be installed by navigating to "Packages" (which should be on the right half of your screen), or by selecting "Tools" at the top of your screen and selecting "Install packages" from there.

2018 Workshop example
=====================
Texts on electric vehicles: 2005-2014.
-------------------
Code tested and written for R version 3.5.1, tm package version 0.7-4, topicmodels package version 0.2-7, igraph version 1.2.1., and LDAVis version 0.3.2.

Code prepared on July 30, 2018 by Richard Haans (haans@rsm.nl).
Data obtained from Hovig Tchalian, used with permission. 

### Loading packages

```Rscript
# The following command loads the required packages.
library(topicmodels)
library(tm)
library(LDAvis)
library(igraph)
```

### Get the data, turn into a corpus, and clean it up
For more information with regards to cleaning, please see the PDW from last year. It can be found <a href="https://github.com/RFJHaans/topicmodeling/blob/master/Code/2017/Formatted%20code%202017.md">here</a> 

```Rscript
#########################################
### Data loading
#########################################
corpus_pr  <-Corpus(DirSource("Texts\\PR"), readerControl = list(reader=readPlain))
corpus_general  <-Corpus(DirSource("Texts\\General"), readerControl = list(reader=readPlain))
# Note that R loads up the texts in alphabetic order based on the filename, even though the folder itself
# was not sorted in this way. It is always good to check how the data are organized after loading to prevent
# errors in data combination further down the road. 

# These files were read locally, but for ease of use, use the command below to load the starting file:
load(url("https://github.com/RFJHaans/topicmodeling/blob/master/Data/2018/Data_pr.RData?raw=true"))
load(url("https://github.com/RFJHaans/topicmodeling/blob/master/Data/2018/Data_general.RData?raw=true"))

#########################################
### Cleaning up the corpus
#########################################
# Below, we clean up the documents in various steps. 
# We write everything to a new corpus called "corpusclean" so that we do not lose the original data.
# 1) Remove numbers
corpusclean_pr <- tm_map(corpus_pr, removeNumbers)
# 2) Remove punctuation
corpusclean_pr <- tm_map(corpusclean_pr, removePunctuation)
# 3) Transform all upper-case letters to lower-case.
corpusclean_pr <- tm_map(corpusclean_pr,  content_transformer(tolower))
# 4) Remove stopwords which do not convey any meaning.
corpusclean_pr <- tm_map(corpusclean_pr, removeWords, stopwords("english")) # this stopword file is at C:\Users\[username]\Documents\R\win-library\2.13\tm\stopwords 
# 5) And strip whitespace. 
corpusclean_pr <- tm_map(corpusclean_pr , stripWhitespace)

# 1) Remove numbers
corpusclean_general <- tm_map(corpus_general, removeNumbers)
# 2) Remove punctuation
corpusclean_general <- tm_map(corpusclean_general, removePunctuation)
# 3) Transform all upper-case letters to lower-case.
corpusclean_general <- tm_map(corpusclean_general,  content_transformer(tolower))
# 4) Remove stopwords which do not convey any meaning.
corpusclean_general <- tm_map(corpusclean_general, removeWords, stopwords("english")) # this stopword file is at C:\Users\[username]\Documents\R\win-library\2.13\tm\stopwords 
# 5) And strip whitespace. 
corpusclean_general <- tm_map(corpusclean_general , stripWhitespace)

# See the help of getTransformations for more possibilities, such as stemming. 

#########################################
### More cleaning: infrequent words and frequent words
#########################################
# We convert the corpus to a "Document-term-matrix" (dtm)
dtm_pr <-DocumentTermMatrix(corpusclean_pr)  
dtm_general <-DocumentTermMatrix(corpusclean_general)  
# dtms are organized with rows being documents and columns being the unique words.

# To speed up the computation process for this tutorial, I have selected some of the most frequent words 
# that don't seem to be very meaningful. 
# We update the corpusclean corpus by removing these words. 
corpusclean_pr <- tm_map(corpusclean_pr, removeWords, c("words","also","can","get","going","just","well","said","will","thats","now","right","like","last","one","see"))
corpusclean_general <- tm_map(corpusclean_general, removeWords, c("words","also","can","get","going","just","well","said","will","thats","now","right","like","last","one","see"))

# We then create a dictionary that contains words occurring more than 50 times. 
highfreq50_pr <- findFreqTerms(dtm_pr,50,Inf)
highfreq50_general <- findFreqTerms(dtm_general,50,Inf)

# and create a smaller dtm
# Note that this is completed on the corpus, not the DTM. 
smalldtm_50w_pr <- DocumentTermMatrix(corpusclean_pr, control=list(dictionary = highfreq50_pr))
smalldtm_50w_general <- DocumentTermMatrix(corpusclean_general, control=list(dictionary = highfreq50_general))

# The following loads the data after processing via the above steps:
load(url("https://github.com/RFJHaans/topicmodeling/blob/master/Data/2018/Data_preTM.RData?raw=true"))
```

### LDA: Running the model
Please see the PDW from last year for some more information on the basic models.  It can be found <a href="https://github.com/RFJHaans/topicmodeling/blob/master/Code/2017/Formatted%20code%202017.md">here</a> 
```Rscript
# We first fix the random seed for future replication.
SEED <- 123456789

#########################################
# 10 Topics
t1_10_pr <- Sys.time()
LDA10_pr <- LDA(smalldtm_50w_pr, k = 10, control = list(seed = SEED, verbose = 1))
t2_10_pr <- Sys.time()

t1_10_general <- Sys.time()
LDA10_general <- LDA(smalldtm_50w_general, k = 10, control = list(seed = SEED, verbose = 1))
t2_10_general <- Sys.time()

# Assess time it took to run:
t2_10_pr- t1_10_pr
t2_10_general- t1_10_general

#########################################
# 25 Topics
t1_25_pr <- Sys.time()
LDA25_pr <- LDA(smalldtm_50w_pr, k = 25, control = list(seed = SEED, verbose = 1))
t2_25_pr <- Sys.time()

t1_25_general <- Sys.time()
LDA25_general <- LDA(smalldtm_50w_general, k = 25, control = list(seed = SEED, verbose = 1))
t2_25_general <- Sys.time()

# Assess time it took to run:
t2_25_pr- t1_25_pr
t2_25_general- t1_25_general

#########################################
# 50 Topics
t1_50_pr <- Sys.time()
LDA50_pr <- LDA(smalldtm_50w_pr, k = 50, control = list(seed = SEED, verbose = 1))
t2_50_pr <- Sys.time()

t1_50_general <- Sys.time()
LDA50_general <- LDA(smalldtm_50w_general, k = 50, control = list(seed = SEED, verbose = 1))
t2_50_general <- Sys.time()

# Assess time it took to run:
t2_50_pr- t1_50_pr
t2_50_general- t1_50_general
```

### LDA: Rendering
```Rscript
#########################################
# Terms per topic

#########################################
# 10 topics
# We then create a variable that captures the top ten terms assigned to the 10-topic model:
topics_LDA10_pr <- terms(LDA10_pr, 10)
# And show the results:
```

```Ruby  
      Topic 1       Topic 2     Topic 3      Topic 4      Topic 5    Topic 6   
 [1,] "million"     "market"    "technology" "market"     "market"   "new"     
 [2,] "new"         "think"     "vehicles"   "million"    "year"     "electric"
 [3,] "company"     "growth"    "energy"     "sales"      "company"  "business"
 [4,] "information" "million"   "power"      "energy"     "think"    "company" 
 [5,] "markets"     "new"       "year"       "year"       "sales"    "vehicle" 
 [6,] "electric"    "company"   "business"   "industry"   "business" "million" 
 [7,] "statements"  "energy"    "new"        "quarter"    "electric" "year"    
 [8,] "quarter"     "products"  "market"     "automotive" "first"    "power"   
 [9,] "power"       "year"      "systems"    "growth"     "table"    "vehicles"
[10,] "energy"      "customers" "statements" "time"       "power"    "inc"  

      Topic 7     Topic 8     Topic 9    Topic 10   
 [1,] "business"  "new"       "electric" "company"  
 [2,] "year"      "growth"    "market"   "year"     
 [3,] "new"       "energy"    "energy"   "quarter"  
 [4,] "think"     "inc"       "quarter"  "vehicle"  
 [5,] "energy"    "electric"  "think"    "product"  
 [6,] "sales"     "business"  "million"  "think"    
 [7,] "first"     "million"   "global"   "million"  
 [8,] "time"      "customers" "battery"  "business" 
 [9,] "companies" "tesla"     "question" "new"      
[10,] "today"     "financial" "year"     "operating"
```

```Rscript
topics_LDA10_general <- terms(LDA10_general, 10)
# And show the results:
topics_LDA10_general
```

```Ruby  
      Topic 1    Topic 2     Topic 3     Topic 4    Topic 5   Topic 6   
 [1,] "car"      "electric"  "know"      "new"      "people"  "tesla"   
 [2,] "vehicles" "time"      "cars"      "first"    "energy"  "new"     
 [3,] "electric" "year"      "president" "obama"    "say"     "company" 
 [4,] "cars"     "president" "people"    "company"  "make"    "percent" 
 [5,] "new"      "price"     "year"      "think"    "think"   "year"    
 [6,] "company"  "cars"      "john"      "electric" "new"     "million" 
 [7,] "year"     "company"   "dont"      "car"      "auto"    "pct"     
 [8,] "gas"      "global"    "big"       "vehicles" "billion" "inc"     
 [9,] "energy"   "million"   "time"      "million"  "know"    "electric"
[10,] "first"    "high"      "years"     "hes"      "years"   "sent" 

      Topic 7      Topic 8  Topic 9    Topic 10 
 [1,] "contact"    "price"  "price"    "price"  
 [2,] "new"        "total"  "electric" "average"
 [3,] "holds"      "new"    "total"    "month"  
 [4,] "location"   "year"   "stock"    "day"    
 [5,] "national"   "day"    "market"   "usd"    
 [6,] "house"      "energy" "high"     "stock"  
 [7,] "street"     "assets" "day"      "company"
 [8,] "energy"     "times"  "year"     "market" 
 [9,] "conference" "month"  "month"    "year"   
[10,] "president"  "market" "insider"  "energy" 
```

```Rscript
#########################################
# 25 topics
topics_LDA25_pr <- terms(LDA25_pr, 25)
# And show the results:
topics_LDA25_pr
```

```Ruby  
      Topic 1       Topic 2      Topic 3          Topic 4       Topic 5     
 [1,] "million"     "market"     "business"       "energy"      "market"    
 [2,] "quarter"     "energy"     "new"            "market"      "business"  
 [3,] "statements"  "company"    "year"           "sales"       "year"      
 [4,] "years"       "think"      "think"          "million"     "sales"     
 [5,] "think"       "years"      "electric"       "markets"     "think"     
 [6,] "company"     "year"       "market"         "year"        "company"   
 [7,] "new"         "new"        "energy"         "automotive"  "table"     
 [8,] "fuel"        "weve"       "million"        "industry"    "electric"  
 [9,] "two"         "growth"     "vehicles"       "growth"      "first"     
[10,] "technology"  "vehicles"   "statements"     "years"       "energy"    
[11,] "energy"      "million"    "forwardlooking" "quarter"     "may"       
[12,] "electric"    "technology" "power"          "table"       "power"     
[13,] "first"       "products"   "technology"     "share"       "europe"    
[14,] "good"        "power"      "first"          "time"        "product"   
[15,] "power"       "markets"    "company"        "global"      "group"     
[16,] "vehicles"    "question"   "weve"           "vehicles"    "automotive"
[17,] "information" "customers"  "sales"          "car"         "battery"   
[18,] "make"        "increase"   "really"         "power"       "companies" 
[19,] "today"       "really"     "lot"            "vehicle"     "world"     
[20,] "really"      "may"        "systems"        "group"       "analysis"  
[21,] "next"        "global"     "companys"       "product"     "years"     
[22,] "growth"      "sales"      "time"           "really"      "markets"   
[23,] "market"      "world"      "companies"      "charging"    "good"      
[24,] "vehicle"     "demand"     "battery"        "world"       "global"    
[25,] "way"         "things"     "make"           "development" "quarter"   

      Topic 6      Topic 7          Topic 8      Topic 9       Topic 10       
 [1,] "company"    "year"           "business"   "market"      "year"         
 [2,] "year"       "business"       "energy"     "electric"    "quarter"      
 [3,] "new"        "think"          "electric"   "energy"      "think"        
 [4,] "power"      "new"            "new"        "quarter"     "company"      
 [5,] "two"        "markets"        "growth"     "information" "business"     
 [6,] "million"    "energy"         "market"     "think"       "million"      
 [7,] "electric"   "first"          "customers"  "question"    "years"        
 [8,] "think"      "two"            "results"    "year"        "new"          
 [9,] "industrial" "technology"     "dont"       "technology"  "vehicle"      
[10,] "vehicles"   "vehicles"       "global"     "global"      "first"        
[11,] "markets"    "time"           "billion"    "growth"      "sales"        
[12,] "good"       "sales"          "quarter"    "may"         "good"         
[13,] "revenue"    "weve"           "future"     "first"       "power"        
[14,] "vehicle"    "charging"       "financial"  "power"       "automotive"   
[15,] "gas"        "okay"           "technology" "million"     "operating"    
[16,] "years"      "costs"          "vehicles"   "weve"        "really"       
[17,] "business"   "statements"     "share"      "battery"     "product"      
[18,] "companies"  "production"     "products"   "revenue"     "technology"   
[19,] "key"        "forwardlooking" "industry"   "statements"  "two"          
[20,] "batteries"  "today"          "million"    "net"         "customers"    
[21,] "china"      "grid"           "china"      "third"       "billion"      
[22,] "inc"        "continue"       "car"        "systems"     "manufacturing"
[23,] "statements" "cost"           "america"    "industry"    "cost"         
[24,] "number"     "capacity"       "look"       "number"      "point"        
[25,] "smart"      "billion"        "report"     "production"  "vehicles"     

      Topic 11     Topic 12         Topic 13      Topic 14         Topic 15     
 [1,] "new"        "year"           "market"      "quarter"        "million"    
 [2,] "million"    "hybrid"         "new"         "business"       "year"       
 [3,] "quarter"    "technology"     "business"    "electric"       "sales"      
 [4,] "business"   "vehicles"       "million"     "new"            "time"       
 [5,] "vehicle"    "power"          "power"       "think"          "vehicles"   
 [6,] "market"     "electric"       "company"     "time"           "product"    
 [7,] "statements" "systems"        "electric"    "year"           "vehicle"    
 [8,] "company"    "company"        "sales"       "growth"         "business"   
 [9,] "fuel"       "quarter"        "growth"      "energy"         "quarter"    
[10,] "technology" "first"          "vehicles"    "million"        "power"      
[11,] "cash"       "product"        "products"    "look"           "think"      
[12,] "energy"     "development"    "vehicle"     "first"          "inc"        
[13,] "power"      "products"       "table"       "market"         "growth"     
[14,] "sales"      "technologies"   "global"      "know"           "information"
[15,] "years"      "information"    "years"       "sales"          "first"      
[16,] "companys"   "think"          "information" "vehicle"        "automotive" 
[17,] "products"   "battery"        "operating"   "today"          "table"      
[18,] "vehicles"   "energy"         "revenue"     "really"         "years"      
[19,] "growth"     "operating"      "share"       "automotive"     "energy"     
[20,] "net"        "fuel"           "product"     "fuel"           "value"      
[21,] "revenue"    "inc"            "question"    "dont"           "next"       
[22,] "including"  "time"           "cash"        "forwardlooking" "make"       
[23,] "cell"       "system"         "think"       "thank"          "today"      
[24,] "electric"   "advanced"       "really"      "cost"           "america"    
[25,] "based"      "forwardlooking" "make"        "number"         "revenue"   

      Topic 16         Topic 17     Topic 18     Topic 19      Topic 20        
 [1,] "vehicle"        "market"     "million"    "company"     "new"           
 [2,] "market"         "electric"   "electric"   "energy"      "year"          
 [3,] "million"        "quarter"    "year"       "technology"  "energy"        
 [4,] "new"            "growth"     "quarter"    "sales"       "technology"    
 [5,] "company"        "new"        "market"     "electric"    "power"         
 [6,] "think"          "sales"      "first"      "car"         "global"        
 [7,] "energy"         "customers"  "sales"      "vehicles"    "vehicles"      
 [8,] "product"        "vehicle"    "industry"   "million"     "think"         
 [9,] "technology"     "industry"   "energy"     "markets"     "information"   
[10,] "growth"         "think"      "companies"  "think"       "sales"         
[11,] "inc"            "first"      "growth"     "report"      "systems"       
[12,] "quarter"        "revenue"    "vehicles"   "first"       "quarter"       
[13,] "power"          "may"        "next"       "statements"  "technologies"  
[14,] "look"           "production" "customers"  "market"      "customers"     
[15,] "number"         "nissan"     "statements" "net"         "forwardlooking"
[16,] "forwardlooking" "year"       "time"       "development" "include"       
[17,] "customers"      "much"       "thank"      "global"      "share"         
[18,] "electric"       "battery"    "business"   "motors"      "business"      
[19,] "time"           "know"       "good"       "new"         "markets"       
[20,] "products"       "forecast"   "vehicle"    "quarter"     "company"       
[21,] "years"          "time"       "look"       "fuel"        "based"         
[22,] "global"         "smart"      "product"    "vehicle"     "car"           
[23,] "year"           "cost"       "much"       "automotive"  "years"         
[24,] "revenue"        "grid"       "products"   "future"      "product"       
[25,] "industry"       "next"       "may"        "business"    "first"       

      Topic 21      Topic 22     Topic 23    Topic 24      Topic 25       
 [1,] "market"      "market"     "electric"  "new"         "market"       
 [2,] "year"        "business"   "market"    "year"        "think"        
 [3,] "energy"      "million"    "company"   "million"     "company"      
 [4,] "business"    "technology" "million"   "growth"      "million"      
 [5,] "million"     "electric"   "business"  "company"     "sales"        
 [6,] "technology"  "think"      "new"       "market"      "technology"   
 [7,] "vehicle"     "products"   "think"     "years"       "years"        
 [8,] "car"         "battery"    "energy"    "inc"         "products"     
 [9,] "electric"    "vehicles"   "vehicles"  "markets"     "year"         
[10,] "products"    "share"      "year"      "information" "statements"   
[11,] "industry"    "call"       "thank"     "industry"    "fuel"         
[12,] "inc"         "company"    "quarter"   "share"       "vehicle"      
[13,] "first"       "hybrid"     "weve"      "global"      "quarter"      
[14,] "vehicles"    "global"     "customers" "vehicle"     "iii"          
[15,] "power"       "car"        "cash"      "two"         "power"        
[16,] "systems"     "terms"      "sales"     "sales"       "development"  
[17,] "really"      "sales"      "markets"   "charging"    "vehicles"     
[18,] "make"        "make"       "financial" "nissan"      "car"          
[19,] "information" "price"      "battery"   "tesla"       "based"        
[20,] "companies"   "product"    "global"    "call"        "really"       
[21,] "company"     "energy"     "months"    "use"         "time"         
[22,] "results"     "world"      "number"    "nrg"         "end"          
[23,] "good"        "little"     "first"     "good"        "markets"      
[24,] "financial"   "year"       "question"  "systems"     "new"          
[25,] "cars"        "cost"       "much"      "electric"    "corresponding"
```

```Rscript
topics_LDA25_general <- terms(LDA25_general, 25)
# And show the results:
topics_LDA25_general
```

```Ruby  
      Topic 1     Topic 2    Topic 3      Topic 4     Topic 5     Topic 6    
 [1,] "company"   "year"     "know"       "obama"     "people"    "tesla"    
 [2,] "pct"       "car"      "people"     "car"       "cars"      "electric" 
 [3,] "year"      "years"    "year"       "year"      "years"     "year"     
 [4,] "vehicles"  "ago"      "time"       "think"     "car"       "new"      
 [5,] "car"       "price"    "years"      "hes"       "billion"   "company"  
 [6,] "cars"      "people"   "big"        "today"     "think"     "cars"     
 [7,] "electric"  "month"    "cars"       "mccain"    "market"    "sent"     
 [8,] "energy"    "cars"     "street"     "first"     "year"      "state"    
 [9,] "million"   "global"   "john"       "electric"  "time"      "inc"      
[10,] "tesla"     "electric" "says"       "companies" "states"    "pct"      
[11,] "market"    "much"     "two"        "million"   "money"     "million"  
[12,] "percent"   "months"   "much"       "new"       "president" "people"   
[13,] "sales"     "states"   "think"      "clip"      "say"       "states"   
[14,] "battery"   "first"    "car"        "company"   "even"      "president"
[15,] "stock"     "contact"  "world"      "end"       "energy"    "energy"   
[16,] "still"     "market"   "video"      "day"       "week"      "percent"  
[17,] "know"      "total"    "three"      "people"    "may"       "musk"     
[18,] "model"     "stock"    "president"  "week"      "day"       "three"    
[19,] "reported"  "dont"     "energy"     "begin"     "percent"   "sales"    
[20,] "people"    "net"      "theyre"     "national"  "end"       "national" 
[21,] "inc"       "battery"  "want"       "good"      "clip"      "plans"    
[22,] "companys"  "time"     "end"        "vehicles"  "much"      "tuesday"  
[23,] "president" "high"     "government" "help"      "american"  "many"     
[24,] "since"     "house"    "really"     "tax"       "know"      "wednesday"
[25,] "first"     "obama"    "cnn"        "money"     "make"      "business" 

      Topic 7         Topic 8    Topic 9     Topic 10   Topic 11     Topic 12  
 [1,] "contact"       "total"    "deadline"  "energy"   "electric"   "year"    
 [2,] "location"      "new"      "dec"       "price"    "year"       "total"   
 [3,] "holds"         "price"    "new"       "day"      "assets"     "electric"
 [4,] "new"           "day"      "car"       "company"  "new"        "price"   
 [5,] "national"      "year"     "cars"      "month"    "energy"     "index"   
 [6,] "president"     "month"    "vehicles"  "new"      "know"       "million" 
 [7,] "house"         "energy"   "nov"       "shares"   "state"      "market"  
 [8,] "conference"    "company"  "gas"       "stock"    "really"     "week"    
 [9,] "director"      "assets"   "notified"  "assets"   "day"        "time"    
[10,] "street"        "market"   "hybrid"    "capital"  "million"    "times"   
[11,] "electric"      "vehicles" "year"      "time"     "president"  "interest"
[12,] "american"      "times"    "energy"    "year"     "times"      "average" 
[13,] "center"        "car"      "company"   "usd"      "volume"     "ago"     
[14,] "vehicles"      "million"  "oil"       "average"  "market"     "ratio"   
[15,] "include"       "location" "fuel"      "people"   "technology" "cars"    
[16,] "international" "sector"   "electric"  "ago"      "york"       "high"    
[17,] "car"           "think"    "two"       "million"  "stocks"     "invested"
[18,] "first"         "dow"      "vehicle"   "car"      "location"   "months"  
[19,] "news"          "net"      "ford"      "market"   "show"       "sales"   
[20,] "energy"        "week"     "hybrids"   "chief"    "today"      "volume"  
[21,] "company"       "months"   "toyota"    "tesla"    "toyota"     "billion" 
[22,] "hybrid"        "gas"      "states"    "total"    "health"     "rank"    
[23,] "discussion"    "says"     "united"    "national" "auto"       "years"   
[24,] "department"    "ago"      "procedure" "times"    "much"       "contact" 
[25,] "technology"    "years"    "group"     "gas"      "public"     "think"   

      Topic 13     Topic 14    Topic 15    Topic 16     Topic 17    Topic 18    
 [1,] "new"        "new"       "new"       "new"        "price"     "new"       
 [2,] "energy"     "car"       "day"       "car"        "stock"     "million"   
 [3,] "electric"   "sent"      "market"    "percent"    "company"   "electric"  
 [4,] "company"    "moved"     "price"     "tesla"      "new"       "percent"   
 [5,] "contact"    "vehicles"  "president" "inc"        "total"     "cars"      
 [6,] "government" "says"      "times"     "people"     "shares"    "first"     
 [7,] "vehicles"   "years"     "total"     "company"    "average"   "energy"    
 [8,] "assets"     "photos"    "electric"  "electric"   "times"     "general"   
 [9,] "month"      "first"     "average"   "make"       "day"       "time"      
[10,] "national"   "percent"   "company"   "model"      "volume"    "company"   
[11,] "global"     "company"   "million"   "say"        "indicator" "president" 
[12,] "street"     "two"       "romney"    "stock"      "month"     "year"      
[13,] "got"        "billion"   "stock"     "says"       "million"   "years"     
[14,] "house"      "million"   "energy"    "chief"      "trailing"  "shares"    
[15,] "people"     "state"     "month"     "two"        "sales"     "two"       
[16,] "big"        "york"      "week"      "sales"      "usd"       "technology"
[17,] "make"       "contact"   "vehicles"  "years"      "market"    "news"      
[18,] "think"      "say"       "volume"    "federal"    "ago"       "tax"       
[19,] "holds"      "vehicle"   "tesla"     "per"        "year"      "billion"   
[20,] "center"     "center"    "sales"     "location"   "energy"    "price"     
[21,] "stocks"     "companies" "open"      "price"      "assets"    "car"       
[22,] "change"     "photo"     "national"  "may"        "open"      "close"     
[23,] "time"       "market"    "usd"       "think"      "interest"  "look"      
[24,] "share"      "upcoming"  "motors"    "government" "week"      "think"     
[25,] "still"      "home"      "volt"      "vehicle"    "global"    "sales"  

      Topic 19    Topic 20     Topic 21    Topic 22      Topic 23   Topic 24    
 [1,] "new"       "obama"      "electric"  "month"       "years"    "day"       
 [2,] "energy"    "dont"       "new"       "price"       "people"   "price"     
 [3,] "people"    "auto"       "vehicles"  "market"      "say"      "year"      
 [4,] "oil"       "know"       "company"   "stock"       "new"      "total"     
 [5,] "house"     "new"        "president" "year"        "think"    "market"    
 [6,] "john"      "president"  "total"     "assets"      "oil"      "electric"  
 [7,] "cars"      "energy"     "year"      "months"      "know"     "stocks"    
 [8,] "think"     "first"      "price"     "energy"      "mccain"   "index"     
 [9,] "way"       "make"       "power"     "week"        "states"   "average"   
[10,] "time"      "car"        "today"     "average"     "back"     "ratio"     
[11,] "much"      "really"     "time"      "time"        "percent"  "company"   
[12,] "contact"   "government" "says"      "capital"     "billion"  "assets"    
[13,] "back"      "people"     "people"    "index"       "says"     "times"     
[14,] "know"      "much"       "month"     "usd"         "cars"     "return"    
[15,] "fuel"      "house"      "rank"      "open"        "work"     "usd"       
[16,] "electric"  "think"      "think"     "car"         "prices"   "rose"      
[17,] "car"       "need"       "sales"     "three"       "may"      "exercise"  
[18,] "vehicles"  "two"        "car"       "total"       "vehicles" "energy"    
[19,] "volt"      "way"        "know"      "dow"         "want"     "shares"    
[20,] "toyota"    "many"       "house"     "value"       "time"     "vehicles"  
[21,] "president" "cars"       "johnson"   "industrials" "lot"      "bearish"   
[22,] "take"      "cnn"        "percent"   "day"         "electric" "research"  
[23,] "three"     "look"       "health"    "relative"    "money"    "president" 
[24,] "national"  "company"    "stock"     "traded"      "company"  "bullish"   
[25,] "state"     "got"        "news"      "vehicle"     "make"     "technology"

      Topic 25   
 [1,] "today"    
 [2,] "price"    
 [3,] "company"  
 [4,] "president"
 [5,] "cars"     
 [6,] "know"     
 [7,] "car"      
 [8,] "stocks"   
 [9,] "percent"  
[10,] "director" 
[11,] "business" 
[12,] "two"      
[13,] "oil"      
[14,] "first"    
[15,] "people"   
[16,] "global"   
[17,] "may"      
[18,] "contact"  
[19,] "month"    
[20,] "motor"    
[21,] "time"     
[22,] "electric" 
[23,] "vehicles" 
[24,] "national" 
[25,] "make
```

```Rscript
#########################################
# 50 topics
topics_LDA50_pr <- terms(LDA50_pr, 50)
# And show the results:
topics_LDA50_pr
```

```Ruby  
      Topic 1       Topic 2        Topic 3          Topic 4        Topic 5      
 [1,] "million"     "energy"       "market"         "market"       "market"     
 [2,] "company"     "new"          "year"           "energy"       "year"       
 [3,] "new"         "think"        "new"            "sales"        "business"   
 [4,] "electric"    "market"       "business"       "year"         "sales"      
 [5,] "power"       "power"        "million"        "million"      "company"    
 [6,] "years"       "vehicles"     "electric"       "automotive"   "think"      
 [7,] "energy"      "year"         "energy"         "car"          "first"      
 [8,] "statements"  "markets"      "think"          "years"        "table"      
 [9,] "sales"       "company"      "statements"     "industry"     "energy"     
[10,] "markets"     "technology"   "company"        "table"        "electric"   
[11,] "quarter"     "million"      "vehicles"       "growth"       "power"      
[12,] "next"        "growth"       "weve"           "product"      "may"        
[13,] "weve"        "global"       "sales"          "markets"      "battery"    
[14,] "car"         "products"     "really"         "group"        "companies"  
[15,] "first"       "information"  "want"           "vehicles"     "europe"     
[16,] "good"        "around"       "power"          "quarter"      "group"      
[17,] "two"         "customers"    "technology"     "world"        "automotive" 
[18,] "business"    "really"       "growth"         "time"         "analysis"   
[19,] "demand"      "car"          "including"      "share"        "years"      
[20,] "battery"     "may"          "revenue"        "company"      "quarter"    

      Topic 6        Topic 7          Topic 8          Topic 9       Topic 10    
 [1,] "new"          "think"          "new"            "market"      "year"      
 [2,] "year"         "year"           "business"       "electric"    "think"     
 [3,] "company"      "business"       "energy"         "energy"      "quarter"   
 [4,] "power"        "energy"         "electric"       "think"       "business"  
 [5,] "think"        "new"            "growth"         "quarter"     "company"   
 [6,] "million"      "two"            "market"         "year"        "good"      
 [7,] "product"      "time"           "customers"      "first"       "new"       
 [8,] "battery"      "first"          "quarter"        "technology"  "sales"     
 [9,] "business"     "technology"     "results"        "information" "first"     
[10,] "electric"     "vehicles"       "vehicles"       "growth"      "years"     
[11,] "vehicle"      "vehicle"        "technology"     "global"      "million"   
[12,] "inc"          "sales"          "billion"        "may"         "customers" 
[13,] "markets"      "production"     "financial"      "power"       "vehicle"   
[14,] "vehicles"     "make"           "cash"           "question"    "really"    
[15,] "table"        "markets"        "car"            "weve"        "power"     
[16,] "two"          "products"       "power"          "revenue"     "two"       
[17,] "china"        "today"          "share"          "million"     "cost"      
[18,] "first"        "say"            "products"       "battery"     "products"  
[19,] "revenue"      "may"            "report"         "production"  "operating" 
[20,] "automotive"   "cost"           "dont"           "next"        "technology"

      Topic 11       Topic 12       Topic 13         Topic 14        
 [1,] "market"       "power"        "market"         "electric"      
 [2,] "quarter"      "vehicles"     "new"            "new"           
 [3,] "sales"        "year"         "business"       "energy"        
 [4,] "new"          "company"      "million"        "think"         
 [5,] "company"      "technology"   "sales"          "million"       
 [6,] "vehicles"     "hybrid"       "company"        "quarter"       
 [7,] "technology"   "electric"     "electric"       "time"          
 [8,] "energy"       "products"     "growth"         "look"          
 [9,] "products"     "technologies" "power"          "business"      
[10,] "electric"     "system"       "vehicles"       "dont"          
[11,] "growth"       "development"  "vehicle"        "year"          
[12,] "years"        "think"        "years"          "vehicle"       
[13,] "power"        "information"  "products"       "growth"        
[14,] "time"         "energy"       "operating"      "first"         
[15,] "global"       "first"        "product"        "today"         
[16,] "information"  "advanced"     "global"         "sales"         
[17,] "make"         "product"      "information"    "really"        
[18,] "companies"    "today"        "table"          "revenue"       
[19,] "world"        "next"         "cash"           "market"        
[20,] "vehicle"      "quarter"      "china"          "know"          

      Topic 15       Topic 16         Topic 17      Topic 18      Topic 19     
 [1,] "million"      "new"            "market"      "million"     "electric"   
 [2,] "year"         "market"         "electric"    "year"        "energy"     
 [3,] "sales"        "energy"         "growth"      "electric"    "company"    
 [4,] "power"        "think"          "sales"       "energy"      "million"    
 [5,] "vehicle"      "company"        "quarter"     "quarter"     "global"     
 [6,] "vehicles"     "technology"     "new"         "market"      "statements" 
 [7,] "quarter"      "million"        "customers"   "vehicles"    "markets"    
 [8,] "inc"          "year"           "think"       "first"       "think"      
 [9,] "growth"       "customers"      "industry"    "next"        "battery"    
[10,] "business"     "sales"          "first"       "customers"   "car"        
[11,] "years"        "growth"         "year"        "statements"  "fuel"       
[12,] "time"         "power"          "time"        "sales"       "first"      
[13,] "first"        "inc"            "vehicle"     "growth"      "time"       
[14,] "automotive"   "quarter"        "may"         "thank"       "vehicles"   
[15,] "revenue"      "vehicle"        "battery"     "make"        "products"   
[16,] "table"        "electric"       "million"     "vehicle"     "really"     
[17,] "cash"         "production"     "price"       "time"        "technology" 
[18,] "new"          "question"       "know"        "new"         "net"        
[19,] "think"        "next"           "car"         "business"    "sales"      
[20,] "energy"       "years"          "increase"    "products"    "revenue"    

      Topic 20         Topic 21       Topic 22        Topic 23      Topic 24     
 [1,] "new"            "market"       "business"      "electric"    "new"        
 [2,] "year"           "million"      "think"         "market"      "year"       
 [3,] "energy"         "business"     "market"        "company"     "million"    
 [4,] "sales"          "year"         "million"       "business"    "years"      
 [5,] "vehicles"       "energy"       "vehicles"      "think"       "company"    
 [6,] "company"        "car"          "company"       "new"         "growth"     
 [7,] "think"          "vehicle"      "share"         "million"     "market"     
 [8,] "technology"     "electric"     "electric"      "energy"      "inc"        
 [9,] "global"         "operating"    "technology"    "year"        "information"
[10,] "business"       "company"      "make"          "customers"   "share"      
[11,] "car"            "inc"          "global"        "vehicles"    "vehicle"    
[12,] "power"          "financial"    "financial"     "sales"       "two"        
[13,] "years"          "end"          "information"   "cash"        "electric"   
[14,] "customers"      "products"     "products"      "weve"        "current"    
[15,] "information"    "industry"     "energy"        "next"        "europe"     
[16,] "product"        "companies"    "battery"       "thank"       "systems"    
[17,] "future"         "technology"   "cost"          "good"        "sales"      
[18,] "time"           "systems"      "product"       "global"      "iii"        
[19,] "technologies"   "first"        "hybrid"        "three"       "nissan"     
[20,] "systems"        "time"         "year"          "battery"     "markets"   

      Topic 25        Topic 26         Topic 27         Topic 28        
 [1,] "market"        "new"            "million"        "million"       
 [2,] "company"       "electric"       "electric"       "technology"    
 [3,] "sales"         "year"           "think"          "business"      
 [4,] "technology"    "business"       "year"           "new"           
 [5,] "think"         "power"          "markets"        "company"       
 [6,] "year"          "technology"     "business"       "cash"          
 [7,] "years"         "company"        "sales"          "year"          
 [8,] "fuel"          "growth"         "global"         "forwardlooking"
 [9,] "new"           "sales"          "energy"         "fuel"          
[10,] "vehicle"       "million"        "product"        "statements"    
[11,] "statements"    "market"         "growth"         "market"        
[12,] "million"       "forwardlooking" "time"           "companys"      
[13,] "vehicles"      "including"      "industry"       "nickel"        
[14,] "quarter"       "systems"        "end"            "quarter"       
[15,] "table"         "companys"       "power"          "zap"           
[16,] "car"           "think"          "customers"      "electric"      
[17,] "products"      "hybrid"         "future"         "products"      
[18,] "iii"           "cost"           "good"           "including"     
[19,] "net"           "industry"       "may"            "systems"       
[20,] "based"         "information"    "vehicles"       "cell"          

      Topic 29         Topic 30       Topic 31     Topic 32       Topic 33    
 [1,] "million"        "think"        "energy"     "vehicle"      "think"     
 [2,] "quarter"        "electric"     "million"    "electric"     "quarter"   
 [3,] "market"         "business"     "electric"   "quarter"      "new"       
 [4,] "year"           "energy"       "business"   "year"         "million"   
 [5,] "power"          "vehicle"      "quarter"    "new"          "vehicles"  
 [6,] "new"            "million"      "markets"    "think"        "business"  
 [7,] "electric"       "growth"       "power"      "battery"      "market"    
 [8,] "revenue"        "vehicles"     "two"        "power"        "weve"      
 [9,] "may"            "markets"      "growth"     "industry"     "year"      
[10,] "question"       "technology"   "end"        "car"          "may"       
[11,] "battery"        "new"          "vehicles"   "technology"   "question"  
[12,] "industry"       "number"       "second"     "inc"          "demand"    
[13,] "vehicles"       "look"         "good"       "customers"    "growth"    
[14,] "company"        "years"        "new"        "global"       "good"      
[15,] "global"         "thank"        "think"      "sales"        "companies" 
[16,] "really"         "call"         "sales"      "markets"      "industry"  
[17,] "automotive"     "financial"    "demand"     "weve"         "customers" 
[18,] "information"    "much"         "vehicle"    "market"       "know"      
[19,] "time"           "production"   "inc"        "today"        "make"      
[20,] "think"          "share"        "china"      "years"        "billion"   

      Topic 34         Topic 35         Topic 36      Topic 37        
 [1,] "electric"       "company"        "energy"      "year"          
 [2,] "year"           "quarter"        "million"     "new"           
 [3,] "first"          "market"         "think"       "million"       
 [4,] "market"         "statements"     "vehicles"    "energy"        
 [5,] "information"    "year"           "business"    "business"      
 [6,] "power"          "weve"           "new"         "first"         
 [7,] "question"       "first"          "first"       "company"       
 [8,] "years"          "sales"          "global"      "market"        
 [9,] "new"            "million"        "growth"      "technology"    
[10,] "sales"          "technology"     "technology"  "markets"       
[11,] "global"         "product"        "electric"    "increase"      
[12,] "weve"           "including"      "quarter"     "think"         
[13,] "vehicles"       "cash"           "years"       "growth"        
[14,] "million"        "want"           "good"        "china"         
[15,] "vehicle"        "forwardlooking" "two"         "vehicle"       
[16,] "companies"      "end"            "fuel"        "years"         
[17,] "fuel"           "question"       "product"     "may"           
[18,] "time"           "companies"      "company"     "products"      
[19,] "forwardlooking" "new"            "number"      "thank"       
[20,] "think"          "good"           "statements"  "systems"     

      Topic 38       Topic 39         Topic 40         Topic 41      
 [1,] "market"       "business"       "time"           "vehicles"    
 [2,] "new"          "electric"       "sales"          "quarter"     
 [3,] "year"         "year"           "first"          "power"       
 [4,] "company"      "market"         "year"           "energy"      
 [5,] "sales"        "million"        "vehicles"       "million"     
 [6,] "technology"   "power"          "market"         "new"         
 [7,] "industry"     "technology"     "things"         "vehicle"     
 [8,] "growth"       "share"          "products"       "systems"     
 [9,] "markets"      "products"       "growth"         "statements"  
[10,] "nissan"       "company"        "technology"     "technology"  
[11,] "think"        "vehicles"       "car"            "first"       
[12,] "product"      "global"         "think"          "year"        
[13,] "world"        "markets"        "business"       "market"      
[14,] "business"     "revenue"        "industry"       "electric"    
[15,] "vehicles"     "vehicle"        "may"            "inc"         
[16,] "vehicle"      "car"            "years"          "revenue"     
[17,] "may"          "systems"        "know"           "sales"       
[18,] "customers"    "charging"       "information"    "fuel"        
[19,] "good"         "including"      "revenue"        "development" 
[20,] "information"  "today"          "make"           "product"     

      Topic 42         Topic 43         Topic 44       Topic 45      Topic 46      
 [1,] "business"       "market"         "market"       "market"      "business"    
 [2,] "markets"        "million"        "company"      "company"     "market"      
 [3,] "company"        "energy"         "energy"       "year"        "sales"       
 [4,] "growth"         "power"          "year"         "think"       "electric"    
 [5,] "million"        "quarter"        "vehicles"     "energy"      "energy"      
 [6,] "think"          "vehicles"       "vehicle"      "business"    "industry"    
 [7,] "quarter"        "electric"       "statements"   "years"       "vehicles"    
 [8,] "year"           "technology"     "industry"     "markets"     "million"     
 [9,] "statements"     "really"         "markets"      "products"    "quarter"     
[10,] "two"            "vehicle"        "products"     "global"      "years"       
[11,] "time"           "think"          "electric"     "product"     "okay"        
[12,] "new"            "inc"            "think"        "system"      "customers"   
[13,] "sales"          "weve"           "may"          "growth"      "global"      
[14,] "today"          "automotive"     "business"     "really"      "new"         
[15,] "first"          "today"          "inc"          "weve"        "power"       
[16,] "really"         "industry"       "really"       "end"         "vehicle"     
[17,] "vehicles"       "global"         "first"        "china"       "information" 
[18,] "technology"     "make"           "technologies" "production"  "weve"        
[19,] "inc"            "look"           "second"       "quarter"     "china"       
[20,] "products"       "hybrid"         "revenue"      "future"      "two"   

      Topic 47      Topic 48         Topic 49        Topic 50        
 [1,] "market"      "electric"       "market"        "business"      
 [2,] "business"    "energy"         "year"          "quarter"       
 [3,] "first"       "million"        "years"         "company"       
 [4,] "quarter"     "market"         "company"       "new"           
 [5,] "company"     "think"          "think"         "year"          
 [6,] "technology"  "industry"       "business"      "think"         
 [7,] "power"       "first"          "sales"         "development"   
 [8,] "inc"         "technology"     "world"         "first"         
 [9,] "automotive"  "vehicle"        "technology"    "million"       
[10,] "products"    "car"            "really"        "products"      
[11,] "operating"   "battery"        "million"       "markets"       
[12,] "markets"     "products"       "power"         "hybrid"        
[13,] "car"         "sales"          "growth"        "forwardlooking"
[14,] "may"         "call"           "products"      "cash"          
[15,] "growth"      "systems"        "product"       "years"         
[16,] "years"       "really"         "new"           "customers"     
[17,] "system"      "new"            "good"          "batteries"     
[18,] "table"       "next"           "two"           "vehicle"       
[19,] "vehicle"     "customers"      "oil"           "battery"       
[20,] "time"        "per"            "vehicles"      "energy" 
```


```Rscript
topics_LDA50_general <- terms(LDA50_general, 50)
# And show the results:
topics_LDA50_general
```

```Ruby  
       Topic 1      Topic 2      Topic 3         Topic 4      Topic 5        
 [1,] "cars"       "year"       "year"          "obama"      "people"       
 [2,] "year"       "car"        "obama"         "think"      "president"    
 [3,] "vehicles"   "cars"       "know"          "today"      "think"        
 [4,] "company"    "electric"   "cars"          "electric"   "energy"       
 [5,] "electric"   "month"      "people"        "car"        "know"         
 [6,] "tesla"      "price"      "mccain"        "hes"        "time"         
 [7,] "first"      "contact"    "end"           "companies"  "even"         
 [8,] "still"      "million"    "says"          "first"      "states"       
 [9,] "energy"     "global"     "want"          "million"    "price"        
[10,] "car"        "house"      "big"           "company"    "american"     
[11,] "sales"      "years"      "time"          "week"       "say"          
[12,] "new"        "federal"    "car"           "year"       "billion"      
[13,] "stock"      "billion"    "really"        "new"        "car"          
[14,] "reported"   "two"        "barack"        "look"       "much"         
[15,] "battery"    "total"      "think"         "gas"        "money"        
[16,] "percent"    "dont"       "president"     "begin"      "make"         
[17,] "people"     "time"       "years"         "people"     "day"          
[18,] "many"       "much"       "electric"      "national"   "market"       
[19,] "tuesday"    "sales"      "john"          "lot"        "three"        
[20,] "market"     "people"     "cnn"           "sales"      "years"        

      Topic 6      Topic 7         Topic 8      Topic 9       Topic 10     
 [1,] "tesla"      "president"     "new"        "deadline"    "new"        
 [2,] "company"    "contact"       "total"      "new"         "price"      
 [3,] "electric"   "location"      "price"      "car"         "energy"     
 [4,] "state"      "holds"         "day"        "cars"        "company"    
 [5,] "cars"       "electric"      "year"       "notified"    "day"        
 [6,] "year"       "national"      "month"      "dec"         "month"      
 [7,] "new"        "conference"    "energy"     "nov"         "assets"     
 [8,] "sent"       "energy"        "company"    "year"        "people"     
 [9,] "inc"        "director"      "vehicles"   "gas"         "time"       
[10,] "pct"        "new"           "car"        "fuel"        "average"    
[11,] "may"        "company"       "times"      "two"         "year"       
[12,] "president"  "center"        "says"       "hybrid"      "national"   
[13,] "time"       "technology"    "location"   "vehicles"    "capital"    
[14,] "washington" "vehicles"      "market"     "oil"         "stock"      
[15,] "energy"     "health"        "assets"     "toyota"      "total"      
[16,] "people"     "american"      "government" "vehicle"     "honda"      
[17,] "years"      "department"    "million"    "simplified"  "business"   
[18,] "sales"      "hearing"       "week"       "procedure"   "car"        
[19,] "musk"       "include"       "sector"     "years"       "shares"     
[20,] "tuesday"    "room"          "dow"        "first"       "ago"        

      Topic 11     Topic 12     Topic 13     Topic 14     Topic 15     
 [1,] "electric"   "electric"   "electric"   "company"    "new"        
 [2,] "year"       "total"      "new"        "assets"     "day"        
 [3,] "new"        "year"       "company"    "new"        "sales"      
 [4,] "energy"     "price"      "energy"     "billion"    "market"     
 [5,] "know"       "times"      "vehicles"   "vehicles"   "electric"   
 [6,] "president"  "week"       "assets"     "day"        "million"    
 [7,] "day"        "index"      "contact"    "state"      "vehicles"   
 [8,] "million"    "average"    "government" "dont"       "price"      
 [9,] "location"   "market"     "global"     "car"        "company"    
[10,] "state"      "time"       "stocks"     "total"      "month"      
[11,] "york"       "cars"       "people"     "take"       "times"      
[12,] "really"     "interest"   "make"       "first"      "total"      
[13,] "assets"     "ago"        "house"      "know"       "president"  
[14,] "today"      "contact"    "national"   "times"      "stock"      
[15,] "contact"    "high"       "month"      "two"        "shares"     
[16,] "stocks"     "million"    "think"      "percent"    "week"       
[17,] "people"     "ratio"      "holds"      "plant"      "average"    
[18,] "auto"       "billion"    "states"     "economy"    "romney"     
[19,] "way"        "invested"   "day"        "ford"       "motors"     
[20,] "price"      "rank"       "got"        "time"       "energy"     

      Topic 16     Topic 17        Topic 18     Topic 19    Topic 20    
 [1,] "new"        "times"         "new"        "new"       "obama"     
 [2,] "pct"        "price"         "electric"   "oil"       "new"       
 [3,] "inc"        "average"       "cars"       "energy"    "know"      
 [4,] "company"    "shares"        "million"    "think"     "auto"      
 [5,] "percent"    "stock"         "company"    "people"    "make"      
 [6,] "electric"   "new"           "billion"    "back"      "energy"    
 [7,] "car"        "total"         "year"       "john"      "president" 
 [8,] "billion"    "day"           "president"  "hes"       "much"      
 [9,] "tesla"      "market"        "sales"      "way"       "think"     
[10,] "sales"      "week"          "energy"     "much"      "dont"      
[11,] "stock"      "volume"        "percent"    "cars"      "people"    
[12,] "next"       "month"         "general"    "national"  "really"    
[13,] "per"        "company"       "vehicles"   "companies" "first"     
[14,] "people"     "trailing"      "two"        "house"     "car"       
[15,] "maker"      "sales"         "next"       "take"      "got"       
[16,] "reported"   "usd"           "first"      "state"     "need"      
[17,] "may"        "energy"        "tax"        "say"       "look"      
[18,] "federal"    "indicator"     "price"      "vehicles"  "industry"  
[19,] "make"       "open"          "day"        "fuel"      "take"      
[20,] "think"      "assets"        "three"      "car"       "many"      

      Topic 21    Topic 22      Topic 23     Topic 24     Topic 25     Topic 26    
 [1,] "electric"  "month"       "think"      "price"      "cars"       "vehicles"  
 [2,] "new"       "market"      "say"        "day"        "today"      "cars"      
 [3,] "president" "price"       "new"        "electric"   "president"  "say"       
 [4,] "price"     "week"        "people"     "market"     "company"    "energy"    
 [5,] "year"      "stock"       "know"       "average"    "price"      "first"     
 [6,] "vehicles"  "average"     "percent"    "total"      "car"        "years"     
 [7,] "company"   "assets"      "states"     "times"      "stocks"     "know"      
 [8,] "know"      "time"        "says"       "stocks"     "director"   "make"      
 [9,] "people"    "energy"      "want"       "ratio"      "percent"    "people"    
[10,] "time"      "months"      "years"      "assets"     "people"     "electric"  
[11,] "sales"     "open"        "oil"        "index"      "house"      "think"     
[12,] "power"     "electric"    "work"       "year"       "two"        "dont"      
[13,] "today"     "usd"         "lot"        "return"     "global"     "begin"     
[14,] "says"      "contact"     "auto"       "rose"       "know"       "way"       
[15,] "think"     "news"        "big"        "days"       "vehicles"   "year"      
[16,] "news"      "dow"         "money"      "usd"        "business"   "really"    
[17,] "car"       "three"       "billion"    "exercise"   "first"      "hes"       
[18,] "got"       "industrials" "back"       "energy"     "oil"        "end"       
[19,] "total"     "total"       "may"        "rank"       "electric"   "good"      
[20,] "ford"      "times"       "cars"       "company"    "contact"    "state"     

      Topic 27      Topic 28     Topic 29     Topic 30     Topic 31       
 [1,] "price"       "mccain"     "year"       "market"     "price"        
 [2,] "day"         "know"       "electric"   "new"        "electric"     
 [3,] "year"        "two"        "new"        "stock"      "obama"        
 [4,] "month"       "years"      "cars"       "energy"     "president"    
 [5,] "stock"       "year"       "house"      "month"      "first"        
 [6,] "company"     "car"        "vehicles"   "assets"     "tesla"        
 [7,] "million"     "new"        "auto"       "times"      "people"       
 [8,] "global"      "people"     "health"     "year"       "time"         
 [9,] "index"       "oil"        "month"      "shares"     "percent"      
[10,] "new"         "today"      "car"        "million"    "market"       
[11,] "average"     "video"      "total"      "time"       "usd"          
[12,] "assets"      "government" "lot"        "rank"       "think"        
[13,] "rose"        "even"       "two"        "index"      "romney"       
[14,] "total"       "battery"    "chrysler"   "value"      "total"        
[15,] "volume"      "time"       "people"     "ago"        "make"         
[16,] "energy"      "energy"     "vehicle"    "traded"     "energy"       
[17,] "sales"       "electric"   "market"     "business"   "car"          
[18,] "ago"         "good"       "energy"     "open"       "news"         
[19,] "value"       "way"        "companies"  "today"      "stock"        
[20,] "months"      "back"       "united"     "rose"       "million"     

      Topic 32     Topic 33     Topic 34        Topic 35     Topic 36    
 [1,] "electric"   "vehicles"   "street"        "year"       "new"       
 [2,] "year"       "company"    "contact"       "new"        "car"       
 [3,] "market"     "energy"     "new"           "president"  "sent"      
 [4,] "assets"     "people"     "people"        "company"    "million"   
 [5,] "shares"     "united"     "president"     "million"    "tesla"     
 [6,] "price"      "states"     "holds"         "cars"       "moved"     
 [7,] "global"     "much"       "center"        "much"       "electric"  
 [8,] "average"    "think"      "location"      "years"      "photos"    
 [9,] "day"        "electric"   "national"      "people"     "says"      
[10,] "ago"        "hybrid"     "international" "electric"   "cars"      
[11,] "cars"       "may"        "west"          "think"      "percent"   
[12,] "today"      "still"      "state"         "technology" "news"      
[13,] "total"      "gas"        "conference"    "percent"    "company"   
[14,] "months"     "say"        "discussion"    "price"      "make"      
[15,] "first"      "block"      "year"          "says"       "two"       
[16,] "years"      "look"       "oil"           "states"     "billion"   
[17,] "month"      "percent"    "two"           "stock"      "city"      
[18,] "million"    "market"     "theater"       "billion"    "technology"
[19,] "ratio"      "oil"        "car"           "assets"     "york"      
[20,] "high"       "three"      "energy"        "contact"    "business"  

      Topic 37     Topic 38     Topic 39        Topic 40      Topic 41       
 [1,] "year"       "price"      "house"         "day"         "new"          
 [2,] "total"      "total"      "contact"       "ratio"       "location"     
 [3,] "price"      "company"    "car"           "usd"         "american"     
 [4,] "usd"        "stock"      "year"          "week"        "contact"      
 [5,] "company"    "year"       "cars"          "market"      "first"        
 [6,] "capital"    "day"        "director"      "total"       "holds"        
 [7,] "index"      "index"      "street"        "price"       "news"         
 [8,] "electric"   "sector"     "government"    "years"       "national"     
 [9,] "average"    "high"       "know"          "president"   "conference"   
[10,] "stocks"     "capital"    "first"         "assets"      "university"   
[11,] "shares"     "ratio"      "university"    "net"         "street"       
[12,] "market"     "vehicles"   "make"          "year"        "know"         
[13,] "energy"     "stocks"     "senate"        "stock"       "hybrid"       
[14,] "new"        "electric"   "auto"          "ago"         "time"         
[15,] "car"        "new"        "energy"        "trailing"    "energy"       
[16,] "day"        "shares"     "john"          "tesla"       "government"   
[17,] "ago"        "today"      "new"           "bearish"     "cars"         
[18,] "million"    "usd"        "news"          "company"     "include"      
[19,] "interest"   "power"      "national"      "capital"     "vehicles"     
[20,] "volume"     "energy"     "industry"      "average"     "fuel"        

      Topic 42        Topic 43      Topic 44        Topic 45     Topic 46    
 [1,] "years"         "new"         "contact"       "year"       "million"   
 [2,] "president"     "sent"        "car"           "price"      "percent"   
 [3,] "state"         "year"        "electric"      "president"  "electric"  
 [4,] "new"           "vehicles"    "pct"           "global"     "car"       
 [5,] "tesla"         "first"       "cars"          "day"        "company"   
 [6,] "time"          "percent"     "tesla"         "million"    "tesla"     
 [7,] "vehicles"      "says"        "company"       "time"       "inc"       
 [8,] "percent"       "years"       "wednesday"     "month"      "shares"    
 [9,] "company"       "companies"   "rose"          "energy"     "years"     
[10,] "car"           "sales"       "inc"           "company"    "pct"       
[11,] "international" "stock"       "musk"          "good"       "market"    
[12,] "sales"         "states"      "time"          "state"      "price"     
[13,] "year"          "york"        "percent"       "business"   "president" 
[14,] "people"        "two"         "million"       "know"       "close"     
[15,] "house"         "center"      "even"          "first"      "energy"    
[16,] "two"           "thursday"    "general"       "stocks"     "people"    
[17,] "center"        "say"         "news"          "dont"       "two"       
[18,] "billion"       "contact"     "vehicles"      "billion"    "model"     
[19,] "first"         "price"       "much"          "week"       "first"     
[20,] "know"          "upcoming"    "year"          "sales"      "states"    

      Topic 47     Topic 48        Topic 49        Topic 50    
 [1,] "year"       "year"          "new"           "year"      
 [2,] "times"      "new"           "year"          "electric"  
 [3,] "new"        "car"           "energy"        "energy"    
 [4,] "day"        "federal"       "company"       "total"     
 [5,] "years"      "time"          "state"         "know"      
 [6,] "trailing"   "much"          "vehicles"      "month"     
 [7,] "energy"     "model"         "even"          "percent"   
 [8,] "price"      "contact"       "work"          "first"     
 [9,] "month"      "average"       "time"          "price"     
[10,] "market"     "state"         "car"           "average"   
[11,] "car"        "month"         "much"          "battery"   
[12,] "people"     "back"          "people"        "vehicles"  
[13,] "shares"     "ago"           "national"      "car"       
[14,] "today"      "market"        "president"     "technology"
[15,] "capital"    "may"           "government"    "market"    
[16,] "total"      "world"         "wednesday"     "stock"     
[17,] "two"        "international" "research"      "shares"    
[18,] "months"     "years"         "business"      "week"      
[19,] "first"      "first"         "plan"          "national"  
[20,] "volume"     "companies"     "technology"    "president" 
```

### Getting more precise (document-topic / term-topic) matrices to be used in rendering
```Rscript
# Document-topic matrices
documents_LDA10_pr <- as.data.frame(LDA10_pr@gamma) 
documents_LDA10_general <- as.data.frame(LDA10_general@gamma) 
documents_LDA25_pr <- as.data.frame(LDA25_pr@gamma) 
documents_LDA25_general <- as.data.frame(LDA25_general@gamma) 
documents_LDA50_pr <- as.data.frame(LDA50_pr@gamma) 
documents_LDA50_general <- as.data.frame(LDA50_general@gamma) 

#########################################
# Term-topic matrices
terms_LDA10_pr <- posterior(LDA10_pr)[["terms"]]
terms_LDA10_general <- posterior(LDA10_general)[["terms"]]
terms_LDA25_pr <- posterior(LDA25_pr)[["terms"]]
terms_LDA25_general <- posterior(LDA25_general)[["terms"]]
terms_LDA50_pr <- posterior(LDA50_pr)[["terms"]]
terms_LDA50_general <- posterior(LDA50_general)[["terms"]]

#########################################
# Write tables
write.table(documents_LDA10_pr, file = "C:\\Users\\rfjha\\Documents\\GitHub\\topicmodeling\\Output\\2018\\documents_10_pr.csv", sep=',',row.names = FALSE)
write.table(documents_LDA10_general, file = "C:\\Users\\rfjha\\Documents\\GitHub\\topicmodeling\\Output\\2018\\documents_10_general.csv", sep=',',row.names = FALSE)
write.table(documents_LDA25_pr, file = "C:\\Users\\rfjha\\Documents\\GitHub\\topicmodeling\\Output\\2018\\documents_25_pr.csv", sep=',',row.names = FALSE)
write.table(documents_LDA25_general, file = "C:\\Users\\rfjha\\Documents\\GitHub\\topicmodeling\\Output\\2018\\documents_25_general.csv", sep=',',row.names = FALSE)
write.table(documents_LDA50_pr, file = "C:\\Users\\rfjha\\Documents\\GitHub\\topicmodeling\\Output\\2018\\documents_50_pr.csv", sep=',',row.names = FALSE)
write.table(documents_LDA50_general, file = "C:\\Users\\rfjha\\Documents\\GitHub\\topicmodeling\\Output\\2018\\documents_50_general.csv", sep=',',row.names = FALSE)

write.table(terms_LDA10_pr, file = "C:\\Users\\rfjha\\Documents\\GitHub\\topicmodeling\\Output\\2018\\terms_10_pr.csv", sep=',',row.names = FALSE)
write.table(terms_LDA10_general, file = "C:\\Users\\rfjha\\Documents\\GitHub\\topicmodeling\\Output\\2018\\terms_10_general.csv", sep=',',row.names = FALSE)
write.table(terms_LDA25_pr, file = "C:\\Users\\rfjha\\Documents\\GitHub\\topicmodeling\\Output\\2018\\terms_25_pr.csv", sep=',',row.names = FALSE)
write.table(terms_LDA25_general, file = "C:\\Users\\rfjha\\Documents\\GitHub\\topicmodeling\\Output\\2018\\terms_25_general.csv", sep=',',row.names = FALSE)
write.table(terms_LDA50_pr, file = "C:\\Users\\rfjha\\Documents\\GitHub\\topicmodeling\\Output\\2018\\terms_50_pr.csv", sep=',',row.names = FALSE)
write.table(terms_LDA50_general, file = "C:\\Users\\rfjha\\Documents\\GitHub\\topicmodeling\\Output\\2018\\terms_50_general.csv", sep=',',row.names = FALSE)

```

### Creating topic networks (based on term correlations)
```Rscript
# Get the term-topic matrices again
post_10_pr <- topicmodels::posterior(LDA10_pr)
post_10_general <- topicmodels::posterior(LDA10_general)
post_25_pr <- topicmodels::posterior(LDA25_pr)
post_25_general <- topicmodels::posterior(LDA25_general)
post_50_pr <- topicmodels::posterior(LDA50_pr)
post_50_general <- topicmodels::posterior(LDA50_general)

# Create correlation matrices between the topics based on their term-loadings
cor_mat_10_pr <- cor(t(post_10_pr[["terms"]]))
cor_mat_10_general <- cor(t(post_10_general[["terms"]]))
cor_mat_25_pr <- cor(t(post_25_pr[["terms"]]))
cor_mat_25_general <- cor(t(post_25_general[["terms"]]))
cor_mat_50_pr <- cor(t(post_50_pr[["terms"]]))
cor_mat_50_general <- cor(t(post_50_general[["terms"]]))


# Change row values to zero if less than row minimum plus two times the row standard deviation
# The two times was chosen for illustrative purposes. 
# This is similar to how Jockers subsets the distance matrix to keep only 
# closely related documents and avoid a dense spagetti diagram 
# that's difficult to interpret (hat-tip: http://stackoverflow.com/a/16047196/1036500)
cor_mat_10_pr[ sweep(cor_mat_10_pr, 1, (apply(cor_mat_10_pr,1,min) + 2*apply(cor_mat_10_pr,1,sd) )) < 0 ] <- 0
diag(cor_mat_10_pr) <- 0
cor_mat_10_general[ sweep(cor_mat_10_general, 1, (apply(cor_mat_10_general,1,min) + 2*apply(cor_mat_10_general,1,sd) )) < 0 ] <- 0
diag(cor_mat_10_general) <- 0
cor_mat_25_pr[ sweep(cor_mat_25_pr, 1, (apply(cor_mat_25_pr,1,min) + 2*apply(cor_mat_25_pr,1,sd) )) < 0 ] <- 0
diag(cor_mat_25_pr) <- 0
cor_mat_25_general[ sweep(cor_mat_25_general, 1, (apply(cor_mat_25_general,1,min) + 2*apply(cor_mat_25_general,1,sd) )) < 0 ] <- 0
diag(cor_mat_25_general) <- 0
cor_mat_50_pr[ sweep(cor_mat_50_pr, 1, (apply(cor_mat_50_pr,1,min) + 2*apply(cor_mat_50_pr,1,sd) )) < 0 ] <- 0
diag(cor_mat_50_pr) <- 0
cor_mat_50_general[ sweep(cor_mat_50_general, 1, (apply(cor_mat_50_general,1,min) + 2*apply(cor_mat_50_general,1,sd) )) < 0 ] <- 0
diag(cor_mat_50_general) <- 0


# And create graphs:
g_10_pr <- igraph::graph.adjacency(cor_mat_10_pr, weighted = TRUE , mode= 'undirected')
plot(g_10_pr, layout = layout_with_kk, 
     edge.width=E(g_10_pr)$weight, 
     vertex.label.family = "sans",vertex.label.font=2, vertex.color = "white", vertex.label.color = "black")
```
![](https://raw.githubusercontent.com/RFJHaans/topicmodeling/master/Output/2018/10_pr.png)

```Rscript
g_10_general <- igraph::graph.adjacency(cor_mat_10_general, weighted = TRUE , mode= 'undirected')
plot(g_10_general, layout = layout_with_kk, 
     edge.width=E(g_10_general)$weight, 
     vertex.label.family = "sans",vertex.label.font=2, vertex.color = "white", vertex.label.color = "black")
```
![](https://raw.githubusercontent.com/RFJHaans/topicmodeling/master/Output/2018/10_general.png)

```Rscript
g_25_pr <- igraph::graph.adjacency(cor_mat_25_pr, weighted = TRUE , mode= 'undirected')
plot(g_25_pr, layout = layout_with_kk, 
     edge.width=E(g_25_pr)$weight, 
     vertex.label.family = "sans",vertex.label.font=2, vertex.color = "white", vertex.label.color = "black")
```
![](https://raw.githubusercontent.com/RFJHaans/topicmodeling/master/Output/2018/25_pr.png)

```Rscript
g_25_general <- igraph::graph.adjacency(cor_mat_25_general, weighted = TRUE , mode= 'undirected')
plot(g_25_general, layout = layout_with_kk, 
     edge.width=E(g_25_general)$weight, 
     vertex.label.family = "sans",vertex.label.font=2, vertex.color = "white", vertex.label.color = "black")
```
![](https://raw.githubusercontent.com/RFJHaans/topicmodeling/master/Output/2018/25_general.png)

```Rscript
g_50_pr <- igraph::graph.adjacency(cor_mat_50_pr, weighted = TRUE , mode= 'undirected')
plot(g_50_pr, layout = layout_with_kk, 
     edge.width=E(g_50_pr)$weight, 
     vertex.label.family = "sans",vertex.label.font=2, vertex.color = "white", vertex.label.color = "black")
```
![](https://raw.githubusercontent.com/RFJHaans/topicmodeling/master/Output/2018/50_pr.png)

```Rscript
g_50_general <- igraph::graph.adjacency(cor_mat_50_general, weighted = TRUE , mode= 'undirected')
plot(g_50_general, layout = layout_with_kk, 
     edge.width=E(g_50_general)$weight, 
     vertex.label.family = "sans",vertex.label.font=2, vertex.color = "white", vertex.label.color = "black")
```
![](https://raw.githubusercontent.com/RFJHaans/topicmodeling/master/Output/2018/50_general.png)

### Using LDAVis to visualize topics
```Rscript
# We need to create a function that allows converting LDA output from the 'topicmodels' package to LDAVis
# https://gist.github.com/trinker/477d7ae65ff6ca73cace
#' Transform Model Output for Use with the LDAvis Package
topicmodels2LDAvis <- function(x, ...){
  post <- topicmodels::posterior(x)
  if (ncol(post[["topics"]]) < 3) stop("The model must contain > 2 topics")
  mat <- x@wordassignments
  LDAvis::createJSON(
    phi = post[["terms"]], 
    theta = post[["topics"]],
    vocab = colnames(post[["terms"]]),
    doc.length = slam::row_sums(mat, na.rm = TRUE),
    term.frequency = slam::col_sums(mat, na.rm = TRUE)
  )
}

LDAvis::serVis(topicmodels2LDAvis(LDA10_general), out.dir = "C:\\Users\\rfjha\\Documents\\GitHub\\topicmodeling\\Output\\2018\\LDAVis\\vis_10_pr", open.browser = FALSE)

LDAvis::serVis(topicmodels2LDAvis(LDA10_general), out.dir = "C:\\Users\\rfjha\\Documents\\GitHub\\topicmodeling\\Output\\2018\\LDAVis\\vis_10_general", open.browser = FALSE)

LDAvis::serVis(topicmodels2LDAvis(LDA25_general), out.dir = "C:\\Users\\rfjha\\Documents\\GitHub\\topicmodeling\\Output\\2018\\LDAVis\\vis_25_pr", open.browser = FALSE)

LDAvis::serVis(topicmodels2LDAvis(LDA25_general), out.dir = "C:\\Users\\rfjha\\Documents\\GitHub\\topicmodeling\\Output\\2018\\LDAVis\\vis_25_general", open.browser = FALSE)

LDAvis::serVis(topicmodels2LDAvis(LDA50_general), out.dir = "C:\\Users\\rfjha\\Documents\\GitHub\\topicmodeling\\Output\\2018\\LDAVis\\vis_50_pr", open.browser = FALSE)

LDAvis::serVis(topicmodels2LDAvis(LDA50_general), out.dir = "C:\\Users\\rfjha\\Documents\\GitHub\\topicmodeling\\Output\\2018\\LDAVis\\vis_50_general", open.browser = FALSE)

# The following URL points to the data with all the output
load(url("https://github.com/RFJHaans/topicmodeling/blob/master/Data/2018/Data_LDA.RData?raw=true"))

```
Please see <a href="http://www.aclweb.org/anthology/W14-3110">this</a> paper for more information on this visualization (Sievert and Shirley, 2014). 

<a href="http://htmlpreview.github.com/?https://github.com/RFJHaans/topicmodeling/blob/master/Output/2018/LDAVis/vis_10_pr/index.html">10-topic PR</a>  
<a href="http://htmlpreview.github.com/?https://github.com/RFJHaans/topicmodeling/blob/master/Output/2018/LDAVis/vis_10_general/index.html">10-topic General</a>  
<a href="http://htmlpreview.github.com/?https://github.com/RFJHaans/topicmodeling/blob/master/Output/2018/LDAVis/vis_25_pr/index.html">25-topic PR</a>  
<a href="http://htmlpreview.github.com/?https://github.com/RFJHaans/topicmodeling/blob/master/Output/2018/LDAVis/vis_25_general/index.html">25-topic General</a>  
<a href="http://htmlpreview.github.com/?https://github.com/RFJHaans/topicmodeling/blob/master/Output/2018/LDAVis/vis_50_pr/index.html">50-topic PR</a>  
<a href="http://htmlpreview.github.com/?https://github.com/RFJHaans/topicmodeling/blob/master/Output/2018/LDAVis/vis_50_general/index.html">50-topic General</a>  

### The following URL points to the data with all the output
```Rscript
load(url("https://github.com/RFJHaans/topicmodeling/blob/master/Data/2018/Data_LDA.RData?raw=true"))
```
