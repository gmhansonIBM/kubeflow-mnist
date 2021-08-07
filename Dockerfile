# example on how to build docker:
# DOCKER_BUILDKIT=1 docker build -t bdcavanau/kubeflow-mnist . -f Dockerfile
# DOCKER_BUILDKIT=1 docker build --no-cache -t dcavanau/kubeflow-mnist env -f Dockerfile

# example on how to run:
# docker run -it dcavanau/kubeflow-mnist /bin/bash

FROM  tensorflow/tensorflow:2.2.3-gpu-py3
LABEL MAINTAINER "David Cavanaugh <dcavanau@us.ibm.com>"
SHELL ["/bin/bash", "-c"]

# Set the locale
RUN  echo 'Acquire {http::Pipeline-Depth "0";};' >> /etc/apt/apt.conf
RUN DEBIAN_FRONTEND="noninteractive"
RUN apt-get update  && apt-get -y install --no-install-recommends locales && locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt-get install -y --no-install-recommends \
    wget \
    git \
    python3-pip \
    openssh-client \
    python3-setuptools \
    google-perftools && \
    rm -rf /var/lib/apt/lists/*

RUN adduser -u 1000 kflow 

# install conda
WORKDIR /tmp
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc

# build conda environments
COPY environment.yml /tmp/kubeflow-mnist/conda/
RUN /opt/conda/bin/conda update -n base -c defaults conda
RUN /opt/conda/bin/conda env create -f /tmp/kubeflow-mnist/conda/environment.yml
RUN /opt/conda/bin/conda clean -afy

# Cleanup
RUN rm -rf /workspace/{nvidia,docker}-examples && rm -rf /usr/local/nvidia-examples && \
    rm /tmp/kubeflow-mnist/conda/environment.yml

# USER 1000

# switch to the conda environment
RUN echo "conda activate kubeflow-mnist" >> ~/.bashrc
ENV PATH /opt/conda/envs/kubeflow-mnist/bin:$PATH
RUN /opt/conda/bin/activate kubeflow-mnist

# make /bin/sh symlink to bash instead of dash:
RUN echo "dash dash/sh boolean false" | debconf-set-selections && \
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

# Set the new Allocator
ENV LD_PRELOAD /usr/lib/x86_64-linux-gnu/libtcmalloc.so.4