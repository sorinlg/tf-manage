# Multi-architecture support
FROM oraclelinux:9-slim

# Image configuration
ARG AWS_CLI_VERSION='2.15.38'
ARG TERRAFORM_VERSION='1.9.8'
ARG USERNAME='tf'
ARG USER_UID='1001'
ARG USER_GID="${USER_UID}"
ARG TFM_INSTALLER_DIR='/opt/tf-manage-installer'
ARG TFM_INSTALL_PATH='/opt/terraform/tf-manage'
ARG TARGETARCH

# add kubectl yum repo
COPY <<EOF  /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
EOF

RUN \
  # install the required packages
  microdnf -y update \
  && microdnf -y install wget sudo unzip git bash-completion which curl vim procps jq kubectl findutils \
  #
  # create non-root user
  && groupadd --gid $USER_GID $USERNAME \
  && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
  #
  # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
  && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
  && chmod 0440 /etc/sudoers.d/$USERNAME \
  #
  # install the aws cli
  && ARCH=${TARGETARCH} \
  && if [ "${ARCH}" = "amd64" ]; then AWS_ARCH="x86_64"; \
     elif [ "${ARCH}" = "arm64" ]; then AWS_ARCH="aarch64"; \
     else echo "Unsupported architecture: ${ARCH}" && exit 1; fi \
  && curl "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}-${AWS_CLI_VERSION}.zip" -o "awscliv2.zip" \
  && unzip awscliv2.zip \
  && ./aws/install --install-dir /usr/local/aws-cli --bin-dir /usr/local/bin \
  && rm -rf awscliv2.zip aws/ \
  #
  # install yq (YAML processor)
  && YQ_VERSION="v4.44.3" \
  && if [ "${ARCH}" = "amd64" ]; then YQ_ARCH="amd64"; \
     elif [ "${ARCH}" = "arm64" ]; then YQ_ARCH="arm64"; \
     else echo "Unsupported architecture: ${ARCH}" && exit 1; fi \
  && curl -L "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${YQ_ARCH}" -o /usr/local/bin/yq \
  && chmod +x /usr/local/bin/yq \
  #
  # clean cache
  && microdnf clean all \
  #
  # install tfswitch
  && curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/release/install.sh | bash \
  #
  # git config
  && git config --global --add safe.directory /app \
  && git config --global --add safe.directory ${TFM_INSTALLER_DIR}

# switch to non-root user
USER $USERNAME

# install tf-manage
RUN mkdir -p /home/$USERNAME/bin
ENV PATH="${PATH}:/home/$USERNAME/bin"
COPY . "${TFM_INSTALLER_DIR}"
WORKDIR "${TFM_INSTALLER_DIR}"
RUN sudo ./bin/tf_install.sh "${TERRAFORM_VERSION}"
RUN echo "source ${TFM_INSTALL_PATH}/bin/tf_complete.sh" >> /home/$USERNAME/.bashrc

# set the working directory
WORKDIR /app
