# always build for linux/amd64
FROM oraclelinux:9-slim

# Image configuration
ARG AWS_CLI_VERSION='2.15.38'
ARG TERRAFORM_VERSION='1.9.8'
ARG USERNAME='tf'
ARG USER_UID='1001'
ARG USER_GID="${USER_UID}"
ARG TFM_INSTALLER_DIR='/opt/tf-manage-installer'
ARG TFM_INSTALL_PATH='/opt/terraform/tf-manage'

# add kubectl yum repo
COPY <<EOF  /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
EOF

RUN microdnf -y update
RUN microdnf -y install wget sudo shadow-utils unzip git bash-completion which curl vim procps jq kubectl findutils
#
# create non-root user
RUN groupadd --gid $USER_GID $USERNAME
RUN useradd --uid $USER_UID --gid $USER_GID -m $USERNAME
#
# [Optional] Add sudo support. Omit if you don't need to install software after connecting.
RUN echo $USERNAME ALL=\(ALL\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME
RUN chmod 0440 /etc/sudoers.d/$USERNAME

# switch to non-root user
RUN mkdir -p /home/$USERNAME
WORKDIR /home/$USERNAME
USER $USERNAME
#
# install the aws cli
RUN ARCH=$(uname -m) && echo "Debug:  ARCH is ${ARCH}" \
  && if [ "$ARCH" = "x86_64" ]; then ARCH="x86_64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="aarch64"; else echo "Unsupported architecture"; exit 1; fi \
  && curl "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}-${AWS_CLI_VERSION}.zip" -o "awscliv2.zip"
RUN unzip -qq awscliv2.zip
RUN sudo ./aws/install
#
# clean cache
RUN sudo microdnf clean all
#
# install tfswitch
RUN curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/release/install.sh | sudo bash
#
# git config
RUN git config --global --add safe.directory /app
RUN git config --global --add safe.directory ${TFM_INSTALLER_DIR}

# install tf-manage
RUN mkdir -p /home/$USERNAME/bin
ENV PATH="${PATH}:/home/$USERNAME/bin"
COPY . "${TFM_INSTALLER_DIR}"
WORKDIR "${TFM_INSTALLER_DIR}"
RUN ./bin/tf_install.sh "${TERRAFORM_VERSION}"
RUN echo "source ${TFM_INSTALL_PATH}/bin/tf_complete.sh" >> /home/$USERNAME/.bashrc

# set the working directory
WORKDIR /app
