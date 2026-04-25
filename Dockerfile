############ BASE RUNTIME IMAGE ############
FROM python:3.13.5-slim-bookworm AS base

SHELL ["/bin/bash", "-c"]

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV CELERY_APP='cms'
ENV VIRTUAL_ENV=/home/mediacms.io
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Install system dependencies (Native ARM64 versions)
RUN apt-get update -y && \
    apt-get install --no-install-recommends -y \
        supervisor \
        nginx \
        imagemagick \
        procps \
        build-essential \
        pkg-config \
        zlib1g-dev \
        zlib1g \
        libxml2-dev \
        libxmlsec1-dev \
        libxmlsec1-openssl \
        libpq-dev \
        ffmpeg \
        wget \
        unzip \
        dos2unix \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set up virtualenv
RUN mkdir -p /home/mediacms.io/mediacms/logs && \
    python3 -m venv $VIRTUAL_ENV

WORKDIR /home/mediacms.io/mediacms

# Install Python dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir uv && \
    uv pip install --no-binary lxml --no-binary xmlsec -r requirements.txt

# Copy application files
COPY . /home/mediacms.io/mediacms

# Fix permissions and line endings (prevents "no such file or directory" error)
RUN dos2unix ./deploy/docker/*.sh && \
    chmod +x ./deploy/docker/*.sh

# Required for sprite thumbnail generation
COPY deploy/docker/policy.xml /etc/ImageMagick-6/policy.xml

# Default control variables
ENV ENABLE_UWSGI='yes' \
    ENABLE_NGINX='yes' \
    ENABLE_CELERY_BEAT='yes' \
    ENABLE_CELERY_SHORT='yes' \
    ENABLE_CELERY_LONG='yes' \
    ENABLE_MIGRATIONS='yes'

EXPOSE 9000 80

ENTRYPOINT ["./deploy/docker/entrypoint.sh"]
CMD ["./deploy/docker/start.sh"]
