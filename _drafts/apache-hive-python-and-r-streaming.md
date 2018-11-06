---
title: TODO - Apache Hive - Python and R - Streaming
date: 2018-10-29 17:47:13.134000000 -05:00
tags:
- bigdata
- apache
- hive
- python
- r
- anaconda
- streaming
layout: post
---

* http://clarkfitzg.github.io/2017/10/30/hive-udaf-with-R/
* http://clarkfitzg.github.io/2017/10/31/3-billion-rows-with-R/

### Overview


### What is R?
* http://www.r-project.org/

#### Important Packages
* http://cran.r-project.org/web/packages/tm/index.html
* http://cran.r-project.org/web/packages/RWeka/index.html
* http://tm.r-forge.r-project.org/faq.html

### R Examples
#### R REPL
R has a REPL interpreter like Python.
* http://www.win-vector.com/blog/2009/11/r-examine-objects-tutorial/

**Example 1**
```
R> n <- 100
R> x <- 1:n
R> x
R> y <- x + runif(n) - 0.5
R> y
R> data <- data.frame(x,y)
R> data
R> conn <- file("randData.csv", "w")
R> write.table(data, file=conn, row.names=FALSE, col.names=FALSE, sep=",")
R> close(conn)
R> q()
```

**Example 2**
```
R> data <- read.table(file="randData.csv", sep=",")
R> data
R> q()
```

**Example STDIN script**
```
#! /usr/bin/env Rscript
conn <- file("stdin", open="r")
while(length(line <- readLines(conn, n=1, warn=FALSE)) > 0) {
	print(line)
}
close(conn)
```

```bash
chmod +x testRSTDIN.R
cat randData.csv | Rscript testRSTDIN.R
cat randData.csv | ./testRSTDIN.R
```

#### Debugging R Scripts
* `str`
* `inspect`
* `print`

### What is Hive Streaming?
* http://hive.apache.org/
* https://cwiki.apache.org/confluence/display/Hive/LanguageManual+Transform
* http://hortonworks.com/blog/using-r-and-other-non-java-languages-in-mapreduce-and-hive/
* http://www.michael-noll.com/tutorials/writing-an-hadoop-mapreduce-program-in-python/

#### Hive Streaming Examples
**Setup** - `setupHiveStreamingTest.hql`
```
DROP DATABASE IF EXISTS USERNAME_hive_streaming CASCADE;
CREATE DATABASE USERNAME_hive_streaming;

USE USERNAME_hive_streaming;

CREATE EXTERNAL TABLE rawdata (
x STRING,
y STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ‘,’
STORED AS TEXTFILE
LOCATION ‘/user/USERNAME/hive_streaming’;

CREATE TABLE bincat (
	x STRING,
	y STRING
);

CREATE TABLE ridentity (
	x STRING,
	y STRING
);
```

`hive -f setupHiveStreamingTest.hql`
`hive -e "use USERNAME_hive_streaming; select * from rawdata;"`

**`/bin/cat`** - Identity function for Hive streaming using /bin/cat

`hive -e "USE USERNAME_hive_streaming; SELECT TRANSFORM(x) USING '/bin/cat' AS x2 FROM rawdata;"`

**Simple R Script** - Identity function replicated with an R script

`testRHiveStreaming.R`
```
#! /usr/bin/env Rscript

library(tm)

conn <- file('stdin', open = 'r')
while(length(line <- readLines(conn, n=1, warn=F)) > 0) {
	print(line)
}
close(conn)
```

`hive -e "ADD FILE testRHiveStreaming.R; USE USERNAME_hive_streaming; SELECT TRANSFORM(x) USING 'Rscript testRHiveStreaming.R' AS x2 FROM rawdata;"`

R DTM - Defaults

`testRDTM.R`

```
#! /usr/bin/env Rscript

library(tm)

conn <-file('stdin', open = 'r')
while (length(line <- readLines(conn, n = 1, warn = F)) > 0) {
    fields <- unlist(strsplit(line, '\t'))
    id <- fields[[1]]

    text <- gsub("\\|", " ", fields[[2]])

    data <- termFreq(Corpus(VectorSource(text))[[1]], ctrl)

    write.table(cbind(data, id), sep='\t', col.names=F, quote=F)
}
close(conn)
```

`hive -e “ADD FILE testRDTM.R; SELECT TRANSFORM(id, text) USING ‘Rscript testRDTM.R’ as (word, count, id) FROM reuters.data;”`

R DTM - Custom Settings

`testRDTMCustom.R`

```
#! /usr/bin/env Rscript

library(tm)

ctrl <- list(tokenize = scan_tokenizer,
  removePunctuation = list(preserve_intra_word_dashes = TRUE),
  stopwords = stopwords("english"),
  stemming = TRUE,
  wordLengths = c(3, Inf))

conn <-file('stdin', open = 'r')
while (length(line <- readLines(conn, n = 1, warn = F)) > 0) {
    fields <- unlist(strsplit(line, '\t'))
    id <- fields[[1]]

    text <- gsub("\\|", " ", fields[[2]])

    data <- termFreq(Corpus(VectorSource(text))[[1]], ctrl)

    write.table(cbind(data, id), sep='\t', col.names=F, quote=F)
}
close(conn)
```

`hive -e “ADD FILE testRDTMCustom.R; SELECT TRANSFORM(id, text) USING ‘Rscript testRDTMCustom.R’ as (word, count, id) FROM reuters.data;”`

R DTM - Custom Settings - NGrams

`testRDTMCustomNGrams.R`
```
#! /usr/bin/env Rscript

library(RWeka)
library(tm)

custom_ngram_tokenizer <- function(x) NGramTokenizer(x, Weka_control(min=1, max=10))

ctrl <- list(tokenize = custom_ngram_tokenizer,
  removePunctuation = list(preserve_intra_word_dashes = TRUE),
  stopwords = stopwords("english"),
  stemming = TRUE,
  wordLengths = c(3, Inf))

conn <-file('stdin', open = 'r')
while (length(line <- readLines(conn, n = 1, warn = F)) > 0) {
    fields <- unlist(strsplit(line, '\t'))
    id <- fields[[1]]

    text <- gsub("\\|", " ", fields[[2]])

    data <- termFreq(Corpus(VectorSource(text))[[1]], ctrl)

    write.table(cbind(data, id), sep='\t', col.names=F, quote=F)
}
close(conn)
```

`hive -e “ADD FILE testRDTMCustomNGrams.R; SELECT TRANSFORM(id, text) USING ‘Rscript testRDTMCustomNGrams.R’ as (word, count, id) FROM reuters.data;”`

### Debugging Hive Streaming
#### Running without Hive
* `echo "testRow" | map | sort -k1,1 | reduce`
* `cat file | map | sort -k1,1 | reduce`
* `cat file | tr '\001' '\t' | map | sort -k1,1 | reduce`

