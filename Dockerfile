FROM debian:bullseye as builder
ARG VERSION

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    automake \
    build-essential \
    ca-certificates \
    git \
    libtool \
    make \
    pkg-config \
    # Icecast
    libcurl4-openssl-dev \
    libogg-dev \
    libspeex-dev \
    libssl-dev \
    libtheora-dev \
    libvorbis-dev \
    libxml2-dev \
    libxslt1-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
ADD icecast-$VERSION.tar.gz .
RUN if test ! -d icecast-$VERSION; then mv icecast-* icecast-$VERSION; fi

WORKDIR /build/icecast-$VERSION
RUN ./configure \
    --prefix=/usr \
    --sysconfdir=/etc \
    --localstatedir=/var

RUN make
RUN make install DESTDIR=/build/output

FROM debian:bullseye-slim

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    libcurl4 \
    libogg0 \
    libspeex1 \
    libssl1.1 \
    libtheora0 \
    libvorbis0a \
    libxml2  \
    libxslt1.1 \
    && rm -rf /var/lib/apt/lists/*

ENV USER=icecast

RUN adduser --disabled-password --gecos '' --no-create-home $USER

COPY --from=builder /build/output /

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

RUN install --directory --owner=$USER \
    /var/log/icecast

EXPOSE 8000
ENTRYPOINT ["docker-entrypoint"]
USER $USER
CMD ["icecast", "-c", "/etc/icecast.xml"]
