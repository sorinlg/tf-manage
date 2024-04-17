# always build for linux/amd64
FROM --platform=linux/amd64 oraclelinux:9-slim

# Image configuration
ARG AWS_CLI_VERSION='2.15.38'
ARG TERRAFORM_VERSION='1.8.1'
ARG USERNAME='tf'
ARG USER_UID='1001'
ARG USER_GID="${USER_UID}"
ARG TFM_INSTALLER_DIR='/opt/tf-manage-installer'
ARG TFM_INSTALL_PATH='/opt/terraform/tf-manage'

# install the required packages
RUN microdnf -y update
RUN microdnf -y install wget sudo unzip git bash-completion which curl vim procps

# create non-root user
RUN groupadd --gid $USER_GID $USERNAME \
  && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
  #
  # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
  && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
  && chmod 0440 /etc/sudoers.d/$USERNAME

# install the aws cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip" -o "awscliv2.zip" && \
  unzip awscliv2.zip && \
  sudo ./aws/install
RUN microdnf clean all

# install tfswitch
RUN curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/release/install.sh | bash

# switch to non-root user
USER $USERNAME

# install tf-manage
RUN mkdir -p /home/$USERNAME/bin
ENV PATH="${PATH}:/home/$USERNAME/bin"
COPY . "${TFM_INSTALLER_DIR}"
WORKDIR "${TFM_INSTALLER_DIR}"
RUN ./bin/tf_install.sh "${TERRAFORM_VERSION}"
RUN echo "source ${TFM_INSTALL_PATH}/bin/tf_complete.sh" >> /home/$USERNAME/.bashrc
RUN git config --global --add safe.directory /app
RUN git config --global --add safe.directory ${TFM_INSTALLER_DIR}

# set the working directory
WORKDIR /app
