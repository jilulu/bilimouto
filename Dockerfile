# define ffmpeg base
FROM jrottenberg/ffmpeg:4.1-alpine AS ffmpeg-base

FROM alpine:3.11 AS transfer-base
RUN apk add --no-cache wget tar && \
        wget -q https://github.com/Mikubill/transfer/releases/download/v0.4.7/transfer_0.4.7_linux_amd64.tar.gz && \
        tar -xzvf transfer_0.4.7_linux_amd64.tar.gz && \
        chmod +x transfer

FROM alpine:3.11 AS runtime-base
# get Python, PIP, you-get
RUN apk add --no-cache python3 \
        && python3 -m ensurepip \
        && pip3 install --upgrade pip setuptools \
        && rm -r /usr/lib/python*/ensurepip && \
        if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi && \
        if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3 /usr/bin/python; fi && \
        rm -r /root/.cache && \
        pip3 install you-get
# ffmpeg dependencies
RUN apk add --no-cache --update libgcc libstdc++ ca-certificates libcrypto1.1 libssl1.1 libgomp expat git
# copy ffmpeg libraries from ffmpeg base 
COPY --from=ffmpeg-base /usr/local /usr/local
# copy transfer from transfer-base
COPY --from=transfer-base transfer /usr/local/bin/transfer
ENV LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64
# run script
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]