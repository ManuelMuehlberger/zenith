FROM ghcr.io/catthehacker/ubuntu:act-latest

ARG DEBIAN_FRONTEND=noninteractive
ARG FLUTTER_BASE_URL=https://storage.googleapis.com/flutter_infra_release/releases
ARG FLUTTER_VERSION
ARG FLUTTER_ARCHIVE
ARG FLUTTER_SHA256
ARG FLUTTER_HASH
ARG SOURCE_REPOSITORY=unknown
ARG ANDROID_CMDLINE_TOOLS_VERSION=13114758
ARG ANDROID_PLATFORM_API=36
ARG ANDROID_BUILD_TOOLS_VERSION=36.0.0
ARG ANDROID_LEGACY_PLATFORM_API=35
ARG ANDROID_LEGACY_BUILD_TOOLS_VERSION=35.0.0
ARG ANDROID_NDK_VERSION=28.2.13676358

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=/opt/android-sdk
ENV FLUTTER_HOME=/opt/flutter
ENV PUB_CACHE=/opt/pub-cache
ENV ZENITH_PREBUILT_CI_IMAGE=1
ENV PATH=/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:/opt/pub-cache/bin:${PATH}

LABEL org.opencontainers.image.title="Zenith CI Toolchain"
LABEL org.opencontainers.image.description="Prebuilt Java, Flutter, and Android SDK image for Zenith CI."
LABEL org.opencontainers.image.source="${SOURCE_REPOSITORY}"
LABEL org.opencontainers.image.version="${FLUTTER_VERSION}"
LABEL org.opencontainers.image.revision="${FLUTTER_HASH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      bash \
      ca-certificates \
      curl \
      git \
      jq \
      openjdk-17-jdk \
      python3 \
      unzip \
      wget \
      xz-utils \
      zip \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p "${ANDROID_SDK_ROOT}/cmdline-tools" /root/.android \
    && touch /root/.android/repositories.cfg \
    && curl -fsSL "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip" -o /tmp/android-commandlinetools.zip \
    && unzip -q /tmp/android-commandlinetools.zip -d "${ANDROID_SDK_ROOT}/cmdline-tools" \
    && mv "${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools" "${ANDROID_SDK_ROOT}/cmdline-tools/latest" \
  && { yes | sdkmanager --licenses >/dev/null || test $? -eq 141; } \
    && sdkmanager \
      "platform-tools" \
      "platforms;android-${ANDROID_PLATFORM_API}" \
      "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" \
      "platforms;android-${ANDROID_LEGACY_PLATFORM_API}" \
      "build-tools;${ANDROID_LEGACY_BUILD_TOOLS_VERSION}" \
      "ndk;${ANDROID_NDK_VERSION}" \
    && rm -f /tmp/android-commandlinetools.zip

RUN curl -fsSL "${FLUTTER_BASE_URL}/${FLUTTER_ARCHIVE}" -o /tmp/flutter.tar.xz \
    && echo "${FLUTTER_SHA256}  /tmp/flutter.tar.xz" | sha256sum -c - \
  && rm -rf "${FLUTTER_HOME}" \
    && tar -xJf /tmp/flutter.tar.xz -C /opt \
    && rm -f /tmp/flutter.tar.xz

RUN flutter config --no-analytics \
    && flutter precache --android

WORKDIR /workspace