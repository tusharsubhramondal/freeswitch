FROM debian:12

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    git \
    wget \
    curl \
    sudo \
    nano \
    vim \
    ca-certificates \
    gnupg \
    build-essential \
    pkg-config \
    autoconf \
    automake \
    libtool \
    libtool-bin \
    cmake \
    nasm \
    yasm \
    uuid-dev \
    libpcre3-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libspeexdsp-dev \
    libedit-dev \
    libsqlite3-dev \
    libldns-dev \
    libsndfile1-dev \
    libopus-dev \
    libmpg123-dev \
    libshout3-dev \
    libmp3lame-dev \
    libavformat-dev \
    libswscale-dev \
    libavutil-dev \
    libswresample-dev \
    liblua5.4-dev \
    libjpeg-dev \
    zlib1g-dev \
    libtiff-dev \
    libogg-dev \
    libvorbis-dev \
    && \
    rm -rf /var/lib/apt/lists/*