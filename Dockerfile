# always build for linux/amd64
FROM --platform=linux/amd64 oraclelinux:9-slim

# copy the project files
COPY . /opt/tf-manage-installer

# set the working directory
WORKDIR /opt/tf-manage-installer

# install the required packages
RUN microdnf -y update
RUN microdnf -y install wget sudo unzip git bash-completion which curl vim procps
RUN curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/release/install.sh | bash
RUN ./bin/tf_install.sh
RUN microdnf clean all
RUN echo "source /opt/terraform/tf-manage/bin/tf_complete.sh" >> /root/.bashrc
