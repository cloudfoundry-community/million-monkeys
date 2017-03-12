FROM bosh/compiled-release

ADD https://github.com/geofffranks/spruce/releases/download/v1.8.13/spruce-linux-amd64 /usr/bin/spruce
ADD https://github.com/starkandwayne/safe/releases/download/v0.1.3/safe-linux-amd64 /usr/bin/safe

RUN chmod 755 /usr/bin/{spruce,safe}
