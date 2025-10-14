###########################################################################################################
#
# How to build:
#
# docker build -t arkcase/pentaho-ce-install:latest .
#
###########################################################################################################

ARG PUBLIC_REGISTRY="public.ecr.aws"
ARG VER="10.1.48"

ARG TOMCAT_MAJOR_VER="10"
ARG TOMCAT_SRC="https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR_VER}/v${VER}/bin/apache-tomcat-${VER}.tar.gz"

ARG TOMCAT_NATIVE_VER="1.3.1"
ARG TOMCAT_NATIVE_URL="https://archive.apache.org/dist/tomcat/tomcat-connectors/native/${TOMCAT_NATIVE_VER}/source/tomcat-native-${TOMCAT_NATIVE_VER}-src.tar.gz"
ARG TOMCAT_NATIVE_BUILD_HOME="/tomcat-native"

ARG BASE_REGISTRY="${PUBLIC_REGISTRY}"
ARG BASE_REPO="arkcase/base-java"
ARG BASE_VER="22.04"
ARG BASE_VER_PFX=""
ARG BASE_IMG="${BASE_REGISTRY}/${BASE_REPO}:${BASE_VER_PFX}${BASE_VER}"

FROM "${BASE_IMG}" AS builder

RUN apt-get -y install \
        libapr1-dev \
        libssl-dev \
      && \
    apt-get clean

#
# Build the Tomcat native APR connector
#
ARG TOMCAT_NATIVE_URL
ARG TOMCAT_NATIVE_BUILD_HOME
ENV TOMCAT_NATIVE_BUILD_HOME="${TOMCAT_NATIVE_BUILD_HOME}"
COPY --chown=root:root build-script /
RUN /build-script

FROM "${BASE_IMG}"

ARG VER

# Install the only binary dependency for the native library
RUN apt-get -y install \
        libapr1 \
      && \
    apt-get clean

ARG TOMCAT_NATIVE_BUILD_HOME
ARG TOMCAT_SRC

ENV TOMCAT_HOME="${BASE_DIR}/tomcat"
ENV TOMCAT_LIB="${TOMCAT_HOME}/lib"
ENV TOMCAT_NATIVE_HOME="${TOMCAT_LIB}/native"

ENV CATALINA_HOME="${TOMCAT_HOME}"
ENV CATALINA_BASE="${CATALINA_HOME}"
#
# Download and install Tomcat, and remove unwanted stuff
#
RUN mkdir -p "${TOMCAT_HOME}" && \
    curl -fsSL "${TOMCAT_SRC}" | tar --strip-components=1 -C "${TOMCAT_HOME}" -xzvf - && \
    rm -rf "${TOMCAT_HOME}/webapps"/* "${TOMCAT_HOME}/temp"/* "${TOMCAT_HOME}/bin"/*.bat

COPY --from=builder "${TOMCAT_NATIVE_BUILD_HOME}/" "${TOMCAT_NATIVE_HOME}/"

COPY setenv.sh "${TOMCAT_HOME}/bin"
COPY --chown=root:root --chmod=0755 install-tomcat-native-module set-session-cookie-name "/usr/local/bin"
