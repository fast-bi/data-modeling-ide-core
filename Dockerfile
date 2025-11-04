# Top level build args

ARG build_for=linux/amd64
ARG BASE_CODE_SERVER_IMAGE="codercom/code-server:4.105.1-focal"


FROM --platform=$build_for ${BASE_CODE_SERVER_IMAGE}
LABEL maintainer=support@fast.bi

SHELL ["/bin/bash", "-o", "pipefail", "-e", "-u", "-x", "-c"]

USER 0

ENV TZ=Europe/Vilnius

# System setup
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update \
  && apt-get dist-upgrade -y \
  && apt-get install -y --no-install-recommends \
    ssh-client \
    software-properties-common \
    make \
    build-essential \
    ca-certificates \
    libpq-dev \
    curl \
    apt-transport-https \
    gnupg \
    cl-base64 \
    jq \
    uuid-runtime \
    yamllint \
    unzip \
    gcc

# Env vars
ENV PYTHONIOENCODING=utf-8
ENV LANG=C.UTF-8

# Install Python 3.11 on focal (build from source)
RUN apt-get update && apt-get install -y \
    wget \
    xz-utils \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncurses5-dev \
    libncursesw5-dev \
    libffi-dev \
    liblzma-dev \
    tk-dev \
  && rm -rf /var/lib/apt/lists/*
RUN PY_VER=3.11.9 \
  && cd /tmp \
  && wget https://www.python.org/ftp/python/${PY_VER}/Python-${PY_VER}.tar.xz \
  && tar -xf Python-${PY_VER}.tar.xz \
  && cd Python-${PY_VER} \
  && ./configure --enable-optimizations --with-lto \
  && make -j"$(nproc)" \
  && make altinstall \
  && cd / \
  && rm -rf /tmp/Python-${PY_VER} /tmp/Python-${PY_VER}.tar.xz

# Install pip for Python 3.11
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
RUN python3.11 get-pip.py

# Upgrade pip and install other dependencies
RUN python3.11 -m pip install --upgrade pip setuptools wheel yq pytz --no-cache-dir

COPY ./requirements.txt /usr/pypi_app/
RUN python3.11 -m pip install --upgrade -r /usr/pypi_app/requirements.txt --no-cache-dir --ignore-installed

# Create symbolic links for python and pip
RUN ln -s /usr/bin/python3.11 /usr/bin/python
RUN ln -s /usr/local/bin/pip3.11 /usr/bin/pip || true

RUN curl -sL -o /usr/local/bin/yqs https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && chmod a+x /usr/local/bin/yqs
RUN curl -sL https://deb.nodesource.com/setup_20.x | bash - && apt-get install -yq nodejs && npm install -g npm
RUN npm install -g @lightdash/cli

RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
RUN apt update && apt install google-cloud-sdk -y
RUN curl -O https://sfc-repo.snowflakecomputing.com/snowsql/bootstrap/1.4/linux_x86_64/snowsql-1.4.3-linux_x86_64.bash && SNOWSQL_DEST=~/bin SNOWSQL_LOGIN_SHELL=~/.profile bash snowsql-1.4.3-linux_x86_64.bash

# Update Go to the latest version (1.24.1 as of the current date)
RUN curl -O https://dl.google.com/go/go1.25.0.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go1.25.0.linux-amd64.tar.gz \
    && rm go1.25.0.linux-amd64.tar.gz

# Set Go environment variables
ENV PATH="/usr/local/go/bin:${PATH}"
ENV GOPATH="/go"
ENV PATH="${GOPATH}/bin:${PATH}"

# Rebuild fixuid with the updated Go version
RUN git clone https://github.com/boxboat/fixuid.git \
    && cd fixuid \
    && go build \
    && mv fixuid /usr/local/bin/fixuid \
    && chmod 4755 /usr/local/bin/fixuid \
    && cd .. \
    && rm -rf fixuid

RUN apt-get update \
  && apt-get upgrade -y

RUN apt-get clean \
  && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

# Add VSCode Extensions
COPY ./extensions/ /usr/vsix/
COPY ./settings /usr/settings
COPY ./init/ /usr/init
COPY ./data-modeling.md /usr/init/data-modeling.md

RUN chmod +x /usr/init/initialization.sh /usr/init/user_vscode_configuration.sh && chown -R coder:coder /usr/vsix /usr/settings /usr/init

USER 1000

ENV USER=coder

WORKDIR /home/coder

EXPOSE 8080

ENTRYPOINT ["/usr/bin/entrypoint.sh", "--bind-addr", "0.0.0.0:8080", "."]