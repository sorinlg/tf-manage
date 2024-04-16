# always build for linux/amd64
FROM --platform=linux/amd64 oraclelinux:9-slim

# set aws cli version
ARG AWS_CLI_VERSION="2.15.38"

# copy the project files
COPY . /opt/tf-manage-installer

# set the working directory
WORKDIR /opt/tf-manage-installer

# install the required packages
RUN microdnf -y update
RUN microdnf -y install wget sudo unzip git bash-completion which curl vim procps

# install the aws cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip" -o "awscliv2.zip" && \
  unzip awscliv2.zip && \
  sudo ./aws/install

# install tfswitch
RUN curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/release/install.sh | bash

RUN ./bin/tf_install.sh
RUN microdnf clean all
RUN echo "source /opt/terraform/tf-manage/bin/tf_complete.sh" >> /root/.bashrc
