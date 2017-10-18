
FROM jupyter/base-notebook

#-----------------------------------------------------
# Dev Tools
#-----------------------------------------------------
USER root

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
# PyLucene (with conda openjdk 8.0)
#-----------------------------------------------------
ENV JCC_JDK=/opt/conda/pkgs/openjdk-8.0.121-1

RUN conda install --yes --quiet \
    'jcc' \
    'openjdk==8.0.121' \
 && curl http://apache.rediris.es/lucene/pylucene/pylucene-6.5.0-src.tar.gz | tar xz  \
 && cd pylucene-6.5.0 \
 && make all install JCC='python -m jcc' ANT=ant PYTHON=python NUM_FILES=8  \
 && cd .. && rm -r pylucene-6.5.0 
 

#-----------------------------------------------------
# Python dependencies
#-----------------------------------------------------
RUN conda install --yes --quiet \
    'ipywidgets' \
    'gmaps' \
    'plotly' \
    'pandas' \
    'beautifulsoup4==4.6.0' \
    'certifi==2017.4.17' \
    'chardet==3.0.4' \
    'geopy==1.11.0' \
    'idna==2.5' \
    'lxml==3.8.0' \
    'nltk==3.2.4' \
    'numpy==1.13.1' \
    'pymongo==3.4.0' \
    'requests==2.18.1' \
    'six==1.10.0' \
    'urllib3==1.21.1' \
 && conda clean -tipsy \
 && jupyter nbextension enable --py --sys-prefix widgetsnbextension \
 && jupyter nbextension enable --py --sys-prefix gmaps 

USER $NB_USER



