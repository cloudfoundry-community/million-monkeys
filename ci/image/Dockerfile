FROM ubuntu:14.04

RUN locale-gen en_US.UTF-8
RUN dpkg-reconfigure locales
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

#basic deps
RUN apt-get update && apt-get -y upgrade && \
    apt-get install -y \
    	build-essential \
    	git \
    	curl \
    	wget \
    	tar \
      unzip zip \
    	libssl-dev \
    	libreadline-dev \
    	dnsutils \
    	xvfb \
    	jq \
    	realpath \
    	&& apt-get clean

ADD https://github.com/geofffranks/spruce/releases/download/v1.8.13/spruce-linux-amd64 /bin/spruce
ADD https://github.com/starkandwayne/safe/releases/download/v0.1.3/safe-linux-amd64 /bin/safe

RUN chmod 755 /bin/spruce /bin/safe

ENV VAULT_VERSION 0.6.5
RUN wget -qO /tmp/vault.zip https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip && \
      unzip -d /bin /tmp/vault.zip && rm /tmp/vault.zip && chmod 755 /bin/vault

RUN wget https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-0.0.147-linux-amd64 -O /bin/bosh-cli && \
      echo "533342d7663c3e5dc731769e157608c74dd9eccb  /bin/bosh-cli" | sha1sum -c - && \
      chmod +x /bin/bosh-cli
