
#############################
# installing the Horizon CLI
############################
FROM centos:8 AS horizon_cli
COPY horizon-cli*.rpm /data/horizon-cli*.rpm
RUN rpm -i /data/horizon-cli*.rpm


FROM  tensorflow/tensorflow:2.2.3-gpu-py3 AS TensorFlow
LABEL MAINTAINER "David Cavanaugh <dcavanau@us.ibm.com>"

ENV KF_VERSION 1.2.0

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

RUN useradd -m -s /bin/bash -g root -G sudo -u 1000 kflow 

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

# make /bin/sh symlink to bash instead of dash:
RUN echo "dash dash/sh boolean false" | debconf-set-selections && \
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

# switch to the conda environment
RUN echo "conda activate kubeflow-mnist" >> ~/.bashrc
ENV PATH /opt/conda/envs/kubeflow-mnist/bin:$PATH
RUN /opt/conda/bin/activate kubeflow-mnist

# Set the new Allocator
ENV LD_PRELOAD /usr/lib/x86_64-linux-gnu/libtcmalloc.so.4


COPY --from=horizon_cli /usr/bin/hzn /usr/bin/hzn

# Install kfctl
RUN wget https://github.com/kubeflow/kfctl/releases/download/v${KF_VERSION}/kfctl_v${KF_VERSION}-0-gbc038f9_linux.tar.gz && \
    tar -xvf kfctl_v${KF_VERSION}-0-gbc038f9_linux.tar.gz && \
    mv ./kfctl /usr/local/bin/ && \
    rm kfctl_v${KF_VERSION}-0-gbc038f9_linux.tar.gz && \
    kfctl version 

# Copy python files
COPY *.py .

# Pre-process
RUN python preprocessing.py --data_dir=/root/data 
# Train
RUN python train.py --data_dir=/root/data 

# path from /workspace/kubeflow-mnist/output.txt 
RUN export MNIST_PATH=$(cat /workspace/kubeflow-mnist/output.txt) && \
    tar -czvf kubeflow-mnist.tar.gz $MNIST_PATH

# if the zip needs the folder name
#    export MNIST_FOLDER=$(echo $MNIST_PATH | tr "/" "\n" | grep [0-9]) && \
#    tar -czvf kubeflow-mnist-${MNIST_FOLDER}.tar.gz $MNIST_PATH

# curl tar to artfactory

# https://jfrog.com/knowledge-base/how-do-i-deploy-large-files-to-artifactory/
# curl -X PUT -u myUser:myPassword -T test.txt "http://localhost:8081/artifactory/libs-release-local/test/test.txt"

# Push newly created folder to IEAM 
# Tar contents of /workspace dir --> removes need to know folder name
# output.txt has the file path for the new version
# folder is name of gihub repo
# 
# hzn command
# hzn mms publish ...
