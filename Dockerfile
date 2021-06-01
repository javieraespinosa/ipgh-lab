
FROM jupyter/base-notebook:notebook-6.3.0

USER root

#-----------------------------------------------------
# Dev Tools
#-----------------------------------------------------

RUN apt-get update && apt-get install -y --no-install-recommends \
    ant \
    build-essential \
    curl \
    git \
    ivy \
    python-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*


#-----------------------------------------------------
# Python 
#-----------------------------------------------------
# Downgrading to python 3.6
#   https://jupyter-docker-stacks.readthedocs.io/en/latest/using/recipes.html

ENV PYTHON_VERSION="3.6"
ENV CONDA_ENV="Python${PYTHON_VERSION}"

# Create Python 3.x environment and link it to jupyter
RUN conda create --quiet --yes -p $CONDA_DIR/envs/$CONDA_ENV python=$PYTHON_VERSION ipython ipykernel \
 && conda clean --all -f -y

RUN $CONDA_DIR/envs/${CONDA_ENV}/bin/python -m ipykernel install --user --name=${CONDA_ENV} \
 && fix-permissions $CONDA_DIR \
 && fix-permissions /home/$NB_USER

# Set as default python version
ENV PATH="$CONDA_DIR/envs/${CONDA_ENV}/bin:$PATH"
ENV CONDA_DEFAULT_ENV="${CONDA_ENV}"


#-----------------------------------------------------
# OpenJDK
#-----------------------------------------------------

ENV OPENJDK_VERSION="8"
ENV JAVA_HOME="/usr/lib/jvm/java-${OPENJDK_VERSION}-openjdk-amd64"

RUN apt-get -y update && apt-get install --no-install-recommends -y \
    "openjdk-${OPENJDK_VERSION}-jdk-headless" \
    ca-certificates-java \
 && apt-get clean  \
 && rm -rf /var/lib/apt/lists/*


#-----------------------------------------------------
# PyLucene 
#-----------------------------------------------------

ENV PYLUCENE_VERSION="7.7.1"
ENV JCC_JDK=$JAVA_HOME

RUN curl -s "https://archive.apache.org/dist/lucene/pylucene/pylucene-${PYLUCENE_VERSION}-src.tar.gz" | tar xz  \
 && cd pylucene-${PYLUCENE_VERSION} \
 && sed -i 's+http://repo1.maven.org+https://repo1.maven.org+g' lucene-java-${PYLUCENE_VERSION}/lucene/common-build.xml  \
 && sed -i 's+http://uk.maven.org+https://uk.maven.org+g' lucene-java-${PYLUCENE_VERSION}/lucene/common-build.xml  \
# Compile JCC
    && cd jcc \ 
    && python setup.py -q build \
    && python setup.py -q install \ 
    && cd .. \
# Compile Pylucene    
 && make all install JCC='python -m jcc' ANT=ant PYTHON=python NUM_FILES=10  \
 && cd .. \
 && rm -r pylucene-${PYLUCENE_VERSION}


#-----------------------------------------------------
# Python dependencies
#-----------------------------------------------------

# external modules
COPY requirements.txt  /requirements.txt
RUN pip install -r /requirements.txt \
 && jupyter nbextension enable --py --sys-prefix widgetsnbextension \
 && jupyter nbextension enable --py --sys-prefix gmaps 

# local modules
COPY py  /py
RUN fix-permissions  /py
ENV PYTHONPATH=/py:$PYTHONPATH

#-----------------------------------------------------
# Final Config
#-----------------------------------------------------

# nltk files
COPY nltk_data  /usr/local/share/nltk_data

USER $NB_USER
