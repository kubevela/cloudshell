FROM --platform=${BUILDPLATFORM:-linux/amd64} node:18.5.0 AS builder
# Build frontend code which added upload/download button
RUN git clone --depth=1 https://github.com/cloudtty/cloudtty && \
    cp -r cloudtty/html/ /app/
WORKDIR /app
RUN yarn install
RUN yarn run build

# lrzsz (rz/sz, the terminal's upload and download) is no longer packaged for
# Alpine, so it is built from source for the image's platform.
FROM ghcr.io/dtzar/helm-kubectl:3.9 AS lrzsz
RUN apk add --no-cache build-base curl \
    && curl -fsSL https://ohse.de/uwe/releases/lrzsz-0.12.20.tar.gz | tar -xz \
    && cd lrzsz-0.12.20 \
    && CFLAGS="-O2 -Wno-implicit-function-declaration -Wno-implicit-int" ./configure --prefix=/usr --disable-nls \
    && make \
    && make install DESTDIR=/out

FROM ghcr.io/dtzar/helm-kubectl:3.9
ARG VERSION
# The vela CLI to bake in. Separate from VERSION, which tags the image.
ARG VELA_VERSION
# The install scripts pick their binaries by platform; TARGETPLATFORM must be
# declared here for BuildKit to set it in this stage.
ARG TARGETPLATFORM
ENV BUILDPLATFORM=${TARGETPLATFORM:-linux/amd64}
ENV VERSION=${VERSION}
ENV VELA_VERSION=${VELA_VERSION}
COPY install-ttyd.sh /bin/install-ttyd.sh
COPY install-vela.sh /bin/install-vela.sh
COPY --from=lrzsz /out/usr/bin/lrz /out/usr/bin/lsz /usr/bin/
RUN apk -U upgrade \
    && apk add --no-cache ca-certificates vim \
    && ln -s /usr/bin/lrz	/usr/bin/rz \
    && ln -s /usr/bin/lsz	/usr/bin/sz \
    && /bin/install-ttyd.sh \
    && /bin/install-vela.sh

COPY --from=builder /app/dist/inline.html index.html
ENTRYPOINT ttyd