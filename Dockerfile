FROM golang:1.10
WORKDIR /go/src/github.com/GoogleContainerTools/kaniko
COPY ./kaniko-src/ .
# Get GCR credential helper
ADD https://github.com/GoogleCloudPlatform/docker-credential-gcr/releases/download/v1.5.0/docker-credential-gcr_linux_amd64-1.5.0.tar.gz /usr/local/bin/
RUN tar -C /usr/local/bin/ -xvzf /usr/local/bin/docker-credential-gcr_linux_amd64-1.5.0.tar.gz
RUN docker-credential-gcr configure-docker
# Get Amazon ECR credential helper
RUN go get -u github.com/awslabs/amazon-ecr-credential-helper/ecr-login/cli/docker-credential-ecr-login
RUN make -C /go/src/github.com/awslabs/amazon-ecr-credential-helper linux-amd64

COPY . .
RUN make

FROM alpine
RUN apk --no-cache --update add ca-certificates
COPY --from=0 /go/src/github.com/GoogleContainerTools/kaniko/out/executor /usr/local/bin/executor
COPY --from=0 /usr/local/bin/docker-credential-gcr /usr/local/bin/docker-credential-gcr
COPY --from=0 /go/src/github.com/awslabs/amazon-ecr-credential-helper/bin/linux-amd64/docker-credential-ecr-login /usr/local/bin/docker-credential-ecr-login
COPY --from=0 /root/.docker/config.json /root/.docker/config.json
ENV HOME /root
ENV USER /root
ENV DOCKER_CONFIG /root/.docker/
ENV DOCKER_CREDENTIAL_GCR_CONFIG /root/.config/gcloud/docker_credential_gcr_config.json
WORKDIR /workspace
RUN ["docker-credential-gcr", "config", "--token-source=env"]
ENTRYPOINT ["/bin/sh"]
