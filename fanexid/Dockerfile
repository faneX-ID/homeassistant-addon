ARG BUILD_FROM
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

# Setup Environment
ENV LANG=C.UTF-8
ENV PIP_ROOT_USER_ACTION=ignore
ENV PIP_BREAK_SYSTEM_PACKAGES=1
ENV PYTHONUNBUFFERED=1

# Install System Requirements
# hadolint ignore=DL3018,DL3017
RUN \
    apk upgrade --no-cache && \
    apk add --no-cache \
    musl \
    nodejs \
    npm \
    nginx \
    gcc \
    musl-dev \
    libffi-dev \
    curl \
    python3 \
    py3-pip \
    postgresql-client

# --- SOURCE CODE FETCH STAGE (OPTIMISTIC) ---
# Try to download and build during Docker build if repo is public.
# If this fails (e.g. private repo), we continue and let run.sh handle it.

ARG FANEXID_VERSION="latest"

WORKDIR /tmp/build
RUN \
    echo "Attempting to fetch faneX-ID version: ${FANEXID_VERSION}" && \
    # 1. Resolve Version URL
    DOWNLOAD_URL="" && \
    if [ "${FANEXID_VERSION}" = "latest" ]; then \
        # Try to find latest tag via API
        TAG_NAME=$(curl -s https://api.github.com/repos/fanex-id/core/releases/latest | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/'); \
        if [ -n "$TAG_NAME" ]; then \
            echo "Resolved latest version to: ${TAG_NAME}"; \
            DOWNLOAD_URL="https://api.github.com/repos/fanex-id/core/tarball/${TAG_NAME}"; \
        else \
            echo "Could not resolve latest version tag. Skipping build stage."; \
        fi; \
    else \
        DOWNLOAD_URL="https://api.github.com/repos/fanex-id/core/tarball/${FANEXID_VERSION}"; \
    fi && \
    # 2. Try Download & Build (If URL found)
    if [ -n "$DOWNLOAD_URL" ]; then \
        echo "Attempting download from: ${DOWNLOAD_URL}"; \
        if curl -L -f -o source.tar.gz "$DOWNLOAD_URL"; then \
            echo "✅ Download successful (Public Repo). Building image..."; \
            \
            # Extract \
            tar -xzf source.tar.gz --strip-components=1 && \
            \
            # Setup Backend \
            mkdir -p /app/backend && \
            cp -r backend/* /app/backend/ && \
            if [ -f "/app/backend/requirements.txt" ]; then \
                pip3 install --no-cache-dir -r /app/backend/requirements.txt; \
            fi && \
            \
            # Setup Frontend \
            mkdir -p /app/frontend && \
            cd frontend && \
            npm install && \
            npm run build && \
            cp -r dist/* /app/frontend/ && \
            \
            # Cleanup \
            cd / && \
            rm -rf /tmp/build && \
            echo "✅ Build complete. Image is self-contained."; \
        else \
            echo "⚠️ Download failed (likely Private Repo or Invalid Version)."; \
            echo "Skipping build stage. 'run.sh' will handle download with Token."; \
            # Ensure directories are clean/empty so run.sh detects missing code \
            rm -rf /app/backend/* /app/frontend/*; \
            rm -f /tmp/build/source.tar.gz; \
        fi; \
    fi

# Create app directories (if not created by build step)
WORKDIR /app
RUN \
    mkdir -p /app/backend && \
    mkdir -p /app/frontend

# Setup Nginx
COPY nginx.conf /etc/nginx/http.d/default.conf

# Copy Run Script
COPY run.sh /run.sh
RUN chmod a+x /run.sh

# Health check
HEALTHCHECK \
    CMD curl --fail http://127.0.0.1:8000/api/health || exit 1

CMD [ "/run.sh" ]