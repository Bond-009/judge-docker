FROM gcr.io/kaniko-project/executor:latest AS kaniko

FROM hadolint/hadolint:latest-debian

COPY --from=kaniko /kaniko /kaniko
RUN ["chmod", "777", "/kaniko"]

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    apt-get install -y --no-install-recommends jq && \
    apt-get install -y --no-install-recommends sudo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Make sure the students can't find our secret path, which is mounted in
# /mnt with a secure random name.
RUN ["chmod", "711", "/mnt"]

# Add the user which will run the student's code and the judge.
RUN ["useradd", "-m", "runner"]

RUN adduser runner sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN mv /kaniko/executor /kaniko/executor2 && \
    echo '#!/bin/sh\nsudo /kaniko/executor2 "$@"' > /kaniko/executor && \
    chmod +x /kaniko/executor

# As the runner user
USER runner
RUN ["mkdir", "/home/runner/workdir"]

WORKDIR /home/runner/workdir

COPY main.sh /main.sh
