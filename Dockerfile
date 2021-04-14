FROM alpine:latest AS s6-alpine
LABEL maintainer="flo-mic"
LABEL description="Secure web application gateway/firewall"

##
# BASE image preparation
##

# Install base components
RUN apk add --no-cache \
	bash \
	coreutils \
	curl \
	shadow

# environment variables
ENV ARCH="x86_64" \    
    MIRROR=http://dl-cdn.alpinelinux.org/alpine \
    PS1="$(whoami)@$(hostname):$(pwd)\\$ " \
    HOME="/root" \
    TERM="xterm"

# add s6 overlay
ARG OVERLAY_ARCH="amd64"
ADD https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-${OVERLAY_ARCH}-installer /tmp/
RUN chmod +x /tmp/s6-overlay-${OVERLAY_ARCH}-installer \
    && /tmp/s6-overlay-${OVERLAY_ARCH}-installer / \
    && rm /tmp/s6-overlay-${OVERLAY_ARCH}-installer

# Create user
RUN echo "**** create user and make folders ****" \
    && groupmod -g 1000 users \
    && useradd -u 911 -U -d /config -s /bin/false swag \
    && usermod -G users swag \
    && mkdir -p \
	    /config \
	    /defaults

##
# BASE image preparation done
##

# Install build dependencies
RUN echo "**** install build packages ****" \
    && apk add --no-cache --virtual=build-dependencies \
	    cargo \
	    g++ \
	    gcc \
	    libffi-dev \
	    #openssl-dev \
	    #python3-dev \
	    tar

# Install runtime packages
RUN echo "**** install runtime packages ****" \
    && apk add --no-cache --upgrade \
        ca-certificates \
        fail2ban \
        gnupg \
        memcached \
        nginx 

# Cleanup before deploying
RUN echo "**** clean build files ****" \
    && apk del --purge \
	    build-dependencies \
 #for cleanfiles in *.pyc *.pyo; \
#	do \
#	find /usr/lib/python3.*  -iname "${cleanfiles}" -exec rm -f '{}' + \
#	; done && \
    && rm -rf \
	    /tmp/* \
	    /root/.cache \
	    /root/.cargo

# Download dhparam key from https://2ton.com.au/dhtool/
# Get new DHPARAM wget -o /home/user/tmp/dhparam https://2ton.com.au/dhparam/4096
# copy local files

COPY root/ /

# Init
ENTRYPOINT [ "/init" ]

