ARG base_image=ubuntu
ARG base_image_lts=18.04
FROM ${base_image}:${base_image_lts}

RUN apt update \
  && apt install -y git curl dirmngr zip unzip gcc \
  apt-transport-https lsb-release ca-certificates \
  && curl -sL https://deb.nodesource.com/setup_12.x | bash - \
  && apt install -y nodejs \
  && curl -L https://dl.google.com/go/go1.15.linux-amd64.tar.gz -o go.tar.gz \
  && tar -xvf go.tar.gz \
  && mv go /usr/local/ \
  && rm go.tar.gz

ADD offline-package.sh /

ENV GOROOT="/usr/local/go"
ENV PATH="${PATH}:/root/go/bin:/usr/local/go/bin"

ENTRYPOINT ["/offline-package.sh"]
