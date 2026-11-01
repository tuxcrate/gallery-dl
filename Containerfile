ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG APP_VERSION

ENV HOME=/home/tuxcrate \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

COPY requirements.txt /opt/requirements.txt

RUN set -eux; \
    : "${APP_VERSION:?APP_VERSION must be set}"; \
    apk upgrade --no-cache; \
    apk add --no-cache ca-certificates ffmpeg; \
    python3 -m pip install --no-cache-dir --index-url https://pypi.org/simple \
        -r /opt/requirements.txt "gallery-dl==${APP_VERSION}"; \
    test "$(gallery-dl --version)" = "${APP_VERSION}"; \
    python3 -m pip check; \
    python3 -c "import yaml"; \
    gallery-dl --help > /dev/null; \
    ffmpeg -version; \
    ffprobe -version; \
    addgroup -g 1000 tuxcrate; \
    adduser -D -u 1000 -G tuxcrate -h /home/tuxcrate -s /sbin/nologin tuxcrate; \
    mkdir /downloads; \
    chown 1000:1000 /downloads

USER 1000:1000
WORKDIR /downloads

ENTRYPOINT ["gallery-dl"]
CMD ["--help"]
