###########################################################################################################
#
# How to build:
#
# docker build -t arkcase/pentaho-ce-install:latest .
#
###########################################################################################################

ARG FIPS=""
ARG PUBLIC_REGISTRY="public.ecr.aws"
ARG VER="11.0.20"

# In addition to tomcat-X.Y.Z, we also publish tomcat-X and tomcat-X.Y
ARG PUBLISH_MAJOR="true"
ARG PUBLISH_MINOR="true"

ARG TOMCAT_MAJOR_VER="${VER%%.*}"
ARG TOMCAT_MINOR_VER="${VER%.*}"
ARG TOMCAT_KEYS_URL="https://downloads.apache.org/tomcat/tomcat-${TOMCAT_MAJOR_VER}/KEYS"
ARG TOMCAT_KEYS_SIGNER="@apache[.]org$"
ARG TOMCAT_URL="https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR_VER}/v${VER}/bin/apache-tomcat-${VER}.tar.gz"

ARG BASE_REGISTRY="${PUBLIC_REGISTRY}"
ARG BASE_REPO="arkcase/base-java"
ARG BASE_VER="24.04"
ARG BASE_VER_PFX=""
ARG BASE_IMG="${BASE_REGISTRY}/${BASE_REPO}${FIPS}:${BASE_VER_PFX}${BASE_VER}"

ARG TOMCAT_NATIVE_BASE_REG="${BASE_REGISTRY}"
ARG TOMCAT_NATIVE_REPO="arkcase/tomcat-native"
ARG TOMCAT_NATIVE_VER="latest"
ARG TOMCAT_NATIVE_BASE_PFX="${BASE_VER_PFX}"
ARG TOMCAT_NATIVE_IMG="${TOMCAT_NATIVE_BASE_REG}/${TOMCAT_NATIVE_REPO}${FIPS}:${TOMCAT_NATIVE_BASE_PFX}${TOMCAT_NATIVE_VER}"

FROM "${TOMCAT_NATIVE_IMG}" AS tomcat-native

FROM "${BASE_IMG}"

ARG FIPS
ARG VER
ARG TOMCAT_MAJOR_VER
ARG TOMCAT_MINOR_VER

ARG TOMCAT_NATIVE_BUILD_HOME
ARG TOMCAT_KEYS_URL
ARG TOMCAT_KEYS_SIGNER
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
ENV WORK_DIR="${CATALINA_TMPDIR}"

ENV PATH="${TOMCAT_HOME}/bin:${PATH}"

# Install the only binary dependency for the native library
RUN --mount=type=bind,target=/src \
    --mount=type=bind,from=tomcat-native,target=/native \
    apt-get -y install \
        libapr1 \
      && \
    apt-get clean && \
    mkdir -p "${CATALINA_TMPDIR}" && \
    TARFILE="/tomcat.tar.gz" && \
    verified-download --keys "${TOMCAT_KEYS_URL}" --signer "${TOMCAT_KEYS_SIGNER}" "${TOMCAT_URL}" "${TARFILE}" && \
    mkdir -p "${TOMCAT_HOME}" && \
    tar --strip-components=1 -C "${TOMCAT_HOME}" -xzvf "${TARFILE}" && \
    chmod -R u=rwX,go=rX "${TOMCAT_HOME}" && \
    rm -rf "${TARFILE}" && \
    rm -rf "${TOMCAT_HOME}/webapps"/* "${TOMCAT_HOME}/temp"/* "${TOMCAT_HOME}/bin"/*.bat && \
    install -m 0755 -o root -g root -t "${TOMCAT_HOME}/bin" \
        /src/setenv.sh \
      && \
    install -m 0755 -o root -g root -t "/usr/local/bin" \
        /src/install-tomcat-native-module \
        /src/set-session-cookie-name \
      && \
    install -m 0444 -o root -g root -t "${TOMCAT_HOME}/conf/" \
        /src/logging.properties \
        /src/catalina.properties.extra \
      && \
    cat /src/catalina.properties.extra >> "${TOMCAT_HOME}/conf/catalina.properties" && \
    mkdir -p "${TOMCAT_NATIVE_HOME}" && \
    chown root:root "${TOMCAT_NATIVE_HOME}" && \
    chmod 0755 "${TOMCAT_NATIVE_HOME}" && \
    ( tar --group=root --owner=root --mode=u=rwX,go=rX -cvf - /native ) | tar -C "${TOMCAT_NATIVE_HOME}" --strip-components=1 -xvf -
