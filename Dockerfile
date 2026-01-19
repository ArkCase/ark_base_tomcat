###########################################################################################################
#
# How to build:
#
# docker build -t arkcase/pentaho-ce-install:latest .
#
###########################################################################################################

ARG PUBLIC_REGISTRY="public.ecr.aws"
ARG VER="9.0.113"

# In addition to tomcat-X.Y.Z, we also publish tomcat-X and tomcat-X.Y
ARG PUBLISH_MAJOR="true"
ARG PUBLISH_MINOR="true"

ARG TOMCAT_MAJOR_VER="${VER%%.*}"
ARG TOMCAT_MINOR_VER="${VER%.*}"
ARG TOMCAT_KEYS_URL="https://downloads.apache.org/tomcat/tomcat-${TOMCAT_MAJOR_VER}/KEYS"
ARG TOMCAT_URL="https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR_VER}/v${VER}/bin/apache-tomcat-${VER}.tar.gz"

ARG BASE_REGISTRY="${PUBLIC_REGISTRY}"
ARG BASE_REPO="arkcase/base-java"
ARG BASE_VER="22.04"
ARG BASE_VER_PFX=""
ARG BASE_IMG="${BASE_REGISTRY}/${BASE_REPO}:${BASE_VER_PFX}${BASE_VER}"

ARG TOMCAT_NATIVE_BASE_REG="${BASE_REGISTRY}"
ARG TOMCAT_NATIVE_REPO="arkcase/tomcat-native"
ARG TOMCAT_NATIVE_VER="latest"
ARG TOMCAT_NATIVE_BASE_PFX="${BASE_VER_PFX}"
ARG TOMCAT_NATIVE_IMG="${TOMCAT_NATIVE_BASE_REG}/${TOMCAT_NATIVE_REPO}:${TOMCAT_NATIVE_BASE_PFX}${TOMCAT_NATIVE_VER}"

FROM "${TOMCAT_NATIVE_IMG}" AS tomcat-native

FROM "${BASE_IMG}"

ARG VER
ARG TOMCAT_MAJOR_VER
ARG TOMCAT_MINOR_VER

# Install the only binary dependency for the native library
RUN apt-get -y install \
        libapr1 \
      && \
    apt-get clean

ARG TOMCAT_NATIVE_BUILD_HOME
ARG TOMCAT_KEYS_URL
ARG TOMCAT_URL

ENV TOMCAT_VER="${VER}"
ENV TOMCAT_MAJOR_VER="${TOMCAT_MAJOR_VER}"
ENV TOMCAT_MINOR_VER="${TOMCAT_MINOR_VER}"
ENV TOMCAT_HOME="${BASE_DIR}/tomcat"
ENV TOMCAT_LIB="${TOMCAT_HOME}/lib"
ENV TOMCAT_NATIVE_HOME="${TOMCAT_LIB}/native"

ENV CATALINA_HOME="${TOMCAT_HOME}"
ENV CATALINA_BASE="${CATALINA_HOME}"
ENV CATALINA_TMPDIR="${TEMP_DIR}/tomcat"
ENV CATALINA_OUT="${LOGS_DIR}/catalina.out"

ENV PATH="${TOMCAT_HOME}/bin:${PATH}"

RUN mkdir -p "${CATALINA_TMPDIR}"

#
# Download and install Tomcat, and remove unwanted stuff
#
RUN TARFILE="/tomcat.tar.gz" && \
    verified-download --keys "${TOMCAT_KEYS_URL}" "${TOMCAT_URL}" "${TARFILE}" && \
    mkdir -p "${TOMCAT_HOME}" && \
    tar --strip-components=1 -C "${TOMCAT_HOME}" -xzvf "${TARFILE}" && \
    rm -rf "${TARFILE}" && \
    rm -rf "${TOMCAT_HOME}/webapps"/* "${TOMCAT_HOME}/temp"/* "${TOMCAT_HOME}/bin"/*.bat

COPY --from=tomcat-native / "${TOMCAT_NATIVE_HOME}/"

COPY setenv.sh "${TOMCAT_HOME}/bin"
COPY --chown=root:root --chmod=0755 install-tomcat-native-module set-session-cookie-name "/usr/local/bin"
