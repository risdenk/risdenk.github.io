---
title: TODO - Apache Livy - TensorFlowOnSpark
date: 2018-10-29 17:47:13.298000000 -05:00
tags:
- bigdata
- apache
- livy
- spark
- tensorflow
- tensorflowonspark
- anaconda
- miniconda
- python
- hadoop
- hdfs
- machine learning
layout: post
---

### Overview
[Apache Livy](https://livy.apache.org/) provides a [REST interface](https://livy.incubator.apache.org/docs/latest/rest-api.html) for interacting with [Apache Spark](https://spark.apache.org/). 

### Assumptions
* Cluster does not have access to the internet
* Don't have control over the OS installed Python
* No command line access to the cluster
* Use REST for interacting with cluster (including HDFS)
* Use Knox to for REST interactions to the cluster
* Using Apache Livy to launch Spark jobs instead of spark-submit

### Prerequisites
#### Package Python Environment for Spark
##### Install Miniconda
```bash
curl -O https://repo.continuum.io/miniconda/Miniconda2-latest-Linux-x86_64.sh
bash Miniconda2-latest-Linux-x86_64.sh -b
rm -f Miniconda2-latest-Linux-x86_64.sh
export PATH="$HOME/miniconda2/bin:$PATH"
conda update -y conda
conda --version
```

##### Setup Conda Environment `tensorflowonspark_env`
```bash
conda create -n tensorflowonspark_env --copy -y -q python=2 pip
source activate tensorflowonspark_env
pip install --ignore-installed --upgrade https://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-1.5.0-cp27-none-linux_x86_64.whl
pip install tensorflowonspark
source deactivate
```

##### Create zip of Conda Environment `tensorflowonspark_env`
```bash
pushd ~/miniconda2/envs
zip -r ~/tensorflowonspark_env.zip tensorflowonspark_env
popd
```

##### Upload `tensorflowonspark_env.zip` to HDFS
```bash
curl -i \
  -u ${USER} --location-trusted \
  -X PUT --max-time 900 -T ~/tensorflowonspark_env.zip \
  "https://localhost:8443/gateway/default/webhdfs/v1/user/${USER}/tensorflowonspark_env.zip?op=CREATE&overwrite=true"
rm -rf ~/tensorflowonspark_env.zip
```

#### Upload TensorFlowOnSpark Code to HDFS
```bash
curl -L -o ~/TensorFlowOnSpark.zip https://api.github.com/repos/yahoo/TensorFlowOnSpark/zipball/master
curl -i \
  -u ${USER} --location-trusted \
  -X PUT --max-time 900 -T ~/TensorFlowOnSpark.zip \
  "https://localhost:8443/gateway/default/webhdfs/v1/user/${USER}/TensorFlowOnSpark.zip?op=CREATE&overwrite=true"
rm -rf ~/TensorFlowOnSpark.zip
```

### Run MNIST example
#### Download, zip, and upload to HDFS the MNIST dataset
```bash
mkdir -p ~/mnist
pushd ~/mnist
curl -O "http://yann.lecun.com/exdb/mnist/train-images-idx3-ubyte.gz"
curl -O "http://yann.lecun.com/exdb/mnist/train-labels-idx1-ubyte.gz"
curl -O "http://yann.lecun.com/exdb/mnist/t10k-images-idx3-ubyte.gz"
curl -O "http://yann.lecun.com/exdb/mnist/t10k-labels-idx1-ubyte.gz"
zip -r ~/mnist.zip *
popd
curl -i \
  -u ${USER} --location-trusted \
  -X PUT --max-time 900 -T ~/mnist.zip \
  "https://localhost:8443/gateway/default/webhdfs/v1/user/${USER}/mnist.zip?op=CREATE&overwrite=true"
rm -rf ~/minst ~/mnist.zip
```

#### Setup Environment Variables
Note: TensorFlow requires the paths to `libjvm` and `libhdfs` libraries to be set in the `spark.executorEnv.LD_LIBRARY_PATH`.

```bash
export PYSPARK_PYTHON=./Python/tensorflowonspark_env/bin/python
 
# set paths to libjvm and libhdfs
export LIB_JVM=$JAVA_HOME/jre/lib/amd64/server            # path to libjvm
export LIB_HDFS=/usr/hdp/current/hadoop-client/lib/native # path to libhdfs, for TF acccess to HDFS
```

#### Convert the MNIST zip files into HDFS files
Saves images and labels as CSV files on HDFS.

```bash
curl \
  -u ${USER} \
  --location-trusted \
  -H 'X-Requested-by: livy' \
  -H 'Content-Type: application/json' \
  -X POST \
  https://localhost:8443/gateway/default/livy/v1/batches \
  --data "{
    \"proxyUser\": \"${USER}\",
    \"numExecutors\": 4,
    \"executorMemory\": \"4G\",
    \"archives\": [
      \"hdfs:///user/${USER}/tensorflowonspark_env.zip\",
      \"hdfs:///user/${USER}/mnist.zip\"
    ],
    \"conf\": {
      \"spark.yarn.appMasterEnv.PYSPARK_PYTHON\": \"$PYSPARK_PYTHON\"
    },
    \"file\": \"hdfs:///user/${USER}/TensorFlowOnSpark/examples/mnist/mnist_data_setup.py\",
    \"args\": [
      \"--output\", \"mnist/csv\",
      \"--format\", \"csv\"
    ]
  }" | python -m json.tool
```

#### Run distributed MNIST training (using `feed_dict`)
```bash
curl -i \
  -u ${USER} --location-trusted \
  -X DELETE \
  "https://localhost:8443/gateway/default/webhdfs/v1/user/${USER}/mnist_model?op=DELETE&recursive=true"

curl \
  -u ${USER} \
  --location-trusted \
  -H 'X-Requested-by: livy' \
  -H 'Content-Type: application/json' \
  -X POST \
  https://localhost:8443/gateway/default/livy/v1/batches \
  --data "{
    \"proxyUser\": \"${USER}\",
    \"numExecutors\": 4,
    \"executorMemory\": \"27G\",
    \"archives\": [
      \"hdfs:///user/${USER}/tensorflowonspark_env.zip\"
    ],
    \"pyFiles\": [
      \"hdfs:///user/${USER}/TensorFlowOnSpark/examples/mnist/spark/mnist_dist.py\"
    ],
    \"conf\": {
      \"spark.yarn.appMasterEnv.PYSPARK_PYTHON\": \"$PYSPARK_PYTHON\",
      \"spark.dynamicAllocation.enabled\": \"false\",
      \"spark.yarn.maxAppAttempts\": 1,
      \"spark.executorEnv.LD_LIBRARY_PATH\": \"$LIB_JVM:$LIB_HDFS\"
    },
    \"file\": \"hdfs:///user/${USER}/TensorFlowOnSpark/examples/mnist/spark/mnist_spark.py\",
    \"args\": [
      \"--images\", \"mnist/csv/train/images\",
      \"--labels\", \"mnist/csv/train/labels\",
      \"--mode\", \"train\",
      \"--model\", \"mnist_model\"
    ]
  }" | python -m json.tool
```

#### Run distributed MNIST inference (using `feed_dict`)
```bash
curl \
  -u ${USER} \
  --location-trusted \
  -H 'X-Requested-by: livy' \
  -H 'Content-Type: application/json' \
  -X POST \
  https://localhost:8443/gateway/default/livy/v1/batches \
  --data "{
    \"proxyUser\": \"${USER}\",
    \"numExecutors\": 4,
    \"executorMemory\": \"27G\",
    \"archives\": [
      \"hdfs:///user/${USER}/tensorflowonspark_env.zip\"
    ],
    \"pyFiles\": [
      \"hdfs:///user/${USER}/TensorFlowOnSpark/examples/mnist/spark/mnist_dist.py\"
    ],
    \"conf\": {
      \"spark.yarn.appMasterEnv.PYSPARK_PYTHON\": \"$PYSPARK_PYTHON\",
      \"spark.dynamicAllocation.enabled\": \"false\",
      \"spark.yarn.maxAppAttempts\": 1,
      \"spark.executorEnv.LD_LIBRARY_PATH\": \"$LIB_JVM:$LIB_HDFS\"
    },
    \"file\": \"hdfs:///user/${USER}/TensorFlowOnSpark/examples/mnist/spark/mnist_spark.py\",
    \"args\": [
      \"--images\", \"mnist/csv/test/images\",
      \"--labels\", \"mnist/csv/test/labels\",
      \"--mode\", \"inference\",
      \"--model\", \"mnist_model\",
      \"--output\", \"predictions\"
    ]
  }" | python -m json.tool
```

### References
* https://github.com/yahoo/TensorFlowOnSpark/issues/220
* https://www.tensorflow.org/install/install_linux#installing_with_anaconda
* https://github.com/yahoo/TensorFlowOnSpark/wiki/GetStarted_YARN
* https://livy.incubator.apache.org/docs/latest/rest-api.html
* https://blog.cloudera.com/blog/2017/04/use-your-favorite-python-library-on-pyspark-cluster-with-cloudera-data-science-workbench/
* https://blog.cloudera.com/blog/2017/05/create-conda-recipe-to-use-c-extended-python-library-on-pyspark-cluster-with-cloudera-data-science-workbench/
* https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.6.4/bk_command-line-installation/content/configure_yarn_and_mapreduce.html
    * `LD_LIBRARY_PATH=/usr/hdp/${hdp.version}/hadoop/lib/native:/usr/hdp/${hdp.version}/hadoop/lib/native/Linux-amd64-64`
* https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/WebHDFS.html
* https://henning.kropponline.de/2016/09/24/running-pyspark-with-conda-env/
* https://stackoverflow.com/questions/39280638/how-to-share-conda-environments-across-platforms
* `ImportError: /lib64/libc.so.6: version 'GLIBC_2.17' not found`
    * https://github.com/tensorflow/tensorflow/issues/53
    * https://www.liquidweb.com/kb/how-to-check-the-glibc-gnu-libc-version-on-centos-6-and-centos-7/
* `yum install -y zip bzip2` - If building with `docker run --rm -it centos:7 bash`
* https://github.com/tensorflow/tensorflow/issues/2924
* https://github.com/tensorflow/tensorflow/issues/527

**tensorflowpython.sh**
```bash
#!/usr/bin/env bash

set -u
set -e

./tensorflowonspark_env.zip/tensorflowonspark_env/lib/ld-linux-x86-64.so.2 --library-path ./tensorflowonspark_env.zip/tensorflowonspark_env/lib:$LD_LIBRARY_PATH:./tensorflowonspark_env.zip/tensorflowonspark_env/lib64:/usr/lib64/ ./tensorflowonspark_env.zip/tensorflowonspark_env/bin/python
```

