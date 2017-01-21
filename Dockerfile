FROM ubuntu:14.04

# https://swift.org/builds/swift-3.0.2-release/ubuntu1404/swift-3.0.2-RELEASE/swift-3.0.2-RELEASE-ubuntu14.04.tar.gz

ENV SWIFT_BRANCH swift-3.0.2-release
ARG SWIFT_VERSION
ENV SWIFT_VERSION 3.0.2-RELEASE
ENV SWIFT_PLATFORM ubuntu14.04

# Install related packages
RUN apt-get update && \
    apt-get install -y build-essential wget clang libedit-dev python2.7 python2.7-dev libicu52 libcurl3 rsync libxml2 git awscli && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Swift keys
RUN wget -q -O - https://swift.org/keys/all-keys.asc | gpg --import - && \
    gpg --keyserver hkp://pool.sks-keyservers.net --refresh-keys Swift

# Install Swift Ubuntu 14.04 Snapshot
RUN SWIFT_ARCHIVE_NAME=swift-$SWIFT_VERSION-$SWIFT_PLATFORM && \
    SWIFT_URL=https://swift.org/builds/$SWIFT_BRANCH/$(echo "$SWIFT_PLATFORM" | tr -d .)/swift-$SWIFT_VERSION/$SWIFT_ARCHIVE_NAME.tar.gz && \
    wget -q $SWIFT_URL && \
    wget -q $SWIFT_URL.sig && \
    gpg --verify $SWIFT_ARCHIVE_NAME.tar.gz.sig && \
    tar -xzf $SWIFT_ARCHIVE_NAME.tar.gz --directory / --strip-components=1 && \
    rm -rf $SWIFT_ARCHIVE_NAME* /tmp/* /var/tmp/*

# Set Swift Path
ENV PATH /usr/bin:$PATH

# vapor specific part

# fix for /usr/lib/swift/CoreFoundation not being world readable in 05-09 (and possible others)
RUN chmod -R o+r /usr/lib/swift/CoreFoundation

# set up user
ENV USERNAME vapor
RUN adduser --disabled-password ${USERNAME}

WORKDIR /vapor
RUN chown -R ${USERNAME}:${USERNAME} /vapor

# Specify repository and revision via --build-args
# e.g. --build-arg REPO=vapor-example --build-arg REVISION=b389e2a
# REVISION can be a tag or branch
ARG REPO_CLONE_URL
ENV REPO_CLONE_URL https://github.com/jaronoff97/listmkr_backend.git

RUN echo ${REPO_CLONE_URL}
USER ${USERNAME}
RUN git clone ${REPO_CLONE_URL}
WORKDIR /vapor/listmkr_backend
RUN swift build

EXPOSE 8080

CMD .build/debug/App
