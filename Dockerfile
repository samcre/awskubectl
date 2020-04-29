FROM alpine as base
# Use KUBECTL_VERSION build arg to install specific kubectl version.
# docker build --build-arg KUBECTL_VERSION=v1.15.0 --tag awskubectl:latest .
ARG KUBECTL_VERSION

WORKDIR /tmp

RUN apk add --no-cache curl unzip \
  && if [ -z "${KUBECTL_VERSION}" ]; then \
  KUBECTL_URL=https://storage.googleapis.com/kubernetes-release/release/$( curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt )/bin/linux/amd64/kubectl; \
  else \
  KUBECTL_URL=https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl; \
  fi \
  && curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" \
  && curl -LO "${KUBECTL_URL}" -o kubectl \
  && chmod +x kubectl \
  && unzip awscli-bundle.zip

FROM python:3.8-alpine as final

WORKDIR /tmp

COPY --from=base /tmp/awscli-bundle /tmp/awscli-bundle

RUN apk add --no-cache curl bind-tools busybox-extras

RUN ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws \
  && rm -rf /tmp/awscli-bundle

COPY --from=base /tmp/kubectl /usr/local/bin
