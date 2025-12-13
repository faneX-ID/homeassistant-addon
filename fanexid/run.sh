#!/usr/bin/with-contenv bashio

# --- CONFIGURATION ---
DATA_DIR="/data/fanexid"
DB_DIR="$DATA_DIR/database"
PLUGINS_DIR="$DATA_DIR/plugins"
UPLOADS_DIR="$DATA_DIR/uploads"

bashio::log.info "Starting faneX-ID Add-on initialization..."

# --- FACTORY RESET CHECK (DANGEROUS!) ---
if bashio::config.true 'reset_database'; then
    bashio::log.warning "=================================================="
    bashio::log.warning "   ⚠️  DATABASE RESET ENABLED  ⚠️"
    bashio::log.warning "=================================================="
    bashio::log.warning "ALL DATA WILL BE PERMANENTLY DELETED!"
    bashio::log.warning "This includes:"
    bashio::log.warning "  - All user accounts and profiles"
    bashio::log.warning "  - All matches and social connections"
    bashio::log.warning "  - All chat messages and history"
    bashio::log.warning "  - All uploaded files"
    bashio::log.warning "  - All settings and configurations"
    bashio::log.warning "=================================================="

    # Wait 5 seconds to give user time to cancel
    bashio::log.warning "Starting reset in 5 seconds... (Stop add-on NOW to abort)"
    sleep 5

    bashio::log.info "Proceeding with database reset..."

    # Delete all data
    if [ -d "$DATA_DIR" ]; then
        bashio::log.info "Deleting all data..."
        rm -rf "$DATA_DIR"
    fi

    bashio::log.info "=================================================="
    bashio::log.info "   ✅ DATABASE RESET COMPLETE"
    bashio::log.info "=================================================="
    bashio::log.info "All data has been deleted."
    bashio::log.info "The add-on will now restart with a fresh database."
    bashio::log.info ""
    bashio::log.warning "IMPORTANT: Disable 'reset_database' in the add-on settings!"
    bashio::log.warning "Otherwise, the database will be wiped again on next restart."
    bashio::log.info "=================================================="
fi

# --- CREATE DATA DIRECTORIES ---
mkdir -p "$DB_DIR"
mkdir -p "$PLUGINS_DIR"
mkdir -p "$UPLOADS_DIR"

# --- READ CONFIGURATION FROM HA UI ---
bashio::log.info "Reading configuration from Home Assistant..."

# Version
VERSION=$(bashio::config 'version')
bashio::log.info "Target Version: $VERSION"

# Log Level
if bashio::config.has_value 'log_level'; then
    LOG_LEVEL=$(bashio::config 'log_level' | tr '[:lower:]' '[:upper:]')
    case "$LOG_LEVEL" in
        TRACE|DEBUG) LOG_LEVEL="DEBUG" ;;
        NOTICE|INFO) LOG_LEVEL="INFO" ;;
        WARNING) LOG_LEVEL="WARNING" ;;
        ERROR|FATAL) LOG_LEVEL="ERROR" ;;
        *) LOG_LEVEL="INFO" ;;
    esac
    export LOG_LEVEL
    bashio::log.info "Log level set to: $LOG_LEVEL"
fi

# Database Configuration
DB_TYPE=$(bashio::config 'database.type')

if [[ "$DB_TYPE" == "postgresql" ]]; then
    PG_HOST=$(bashio::config 'database.postgresql_host')
    PG_PORT=$(bashio::config 'database.postgresql_port')
    PG_USER=$(bashio::config 'database.postgresql_user')
    PG_PASS=$(bashio::config 'database.postgresql_password')
    PG_DB=$(bashio::config 'database.postgresql_database')

    export DATABASE_URL="postgresql://$PG_USER:$PG_PASS@$PG_HOST:$PG_PORT/$PG_DB"
    bashio::log.info "Using PostgreSQL database at $PG_HOST:$PG_PORT"
else
    export DATABASE_URL="sqlite:///$DB_DIR/fanexid.db"
    bashio::log.info "Using SQLite database"
fi

# Secret Key
if bashio::config.has_value 'secret_key' && [ -n "$(bashio::config 'secret_key')" ]; then
    export SECRET_KEY=$(bashio::config 'secret_key')
    bashio::log.info "Using configured secret key"
else
    # Generate or load secret key
    if [ ! -f "$DATA_DIR/.secret_key" ]; then
        bashio::log.info "Generating secret key..."
        python3 -c 'import secrets; print(secrets.token_urlsafe(32))' > "$DATA_DIR/.secret_key"
    fi
    export SECRET_KEY=$(cat "$DATA_DIR/.secret_key")
    bashio::log.info "Using auto-generated secret key"
fi

# Project Name
export PROJECT_NAME=$(bashio::config 'project_name')

# Debug Mode
if bashio::config.true 'debug'; then
    export DEBUG="true"
    bashio::log.info "Debug mode: ENABLED"
else
    export DEBUG="false"
fi

# Demo Mode
if bashio::config.true 'demo_mode'; then
    export DEMO_MODE="true"
    bashio::log.info "Demo mode: ENABLED (sample data will be generated)"
else
    export DEMO_MODE="false"
fi

# Entra ID / SSO Configuration
if bashio::config.true 'entra.enabled'; then
    bashio::log.info "Configuring Microsoft Entra ID SSO..."
    export ENTRA_CLIENT_ID=$(bashio::config 'entra.client_id')
    export ENTRA_TENANT_ID=$(bashio::config 'entra.tenant_id')
    export ENTRA_CLIENT_SECRET=$(bashio::config 'entra.client_secret')

    if bashio::config.has_value 'entra.redirect_uri' && [ -n "$(bashio::config 'entra.redirect_uri')" ]; then
        export ENTRA_REDIRECT_URI=$(bashio::config 'entra.redirect_uri')
    else
        # Use ingress URL
        export ENTRA_REDIRECT_URI="http://homeassistant.local:8123/api/hassio_ingress/$(bashio::addon.slug)/api/auth/callback"
    fi
    bashio::log.info "Entra ID SSO: ENABLED"
fi

# Version Information
export BACKEND_VERSION="${BUILD_VERSION:-dev}"
export RELEASE_TYPE="addon"

# --- HELPER FUNCTIONS FOR DOWNLOAD ---

# Helper to construct Auth Header if token exists
get_auth_header() {
    local token="$1"
    if [[ -z "$token" ]]; then
        echo ""
    elif [[ "$token" == github_pat_* ]]; then
        echo "Authorization: Bearer $token"
    elif [[ "$token" == ghp_* ]]; then
        echo "Authorization: token $token"
    else
        echo "Authorization: Bearer $token"
    fi
}

# Helper to download with fallback logic
download_file() {
    local url="$1"
    local output="$2"
    local token="$3"

    bashio::log.info "Attempting download from: $url"

    # 1. Try Public Access (No Token)
    bashio::log.debug "Trying public access..."
    # -f fails silently on server errors (404/403)
    if curl -L -f -H "Accept: application/vnd.github.v3+json" "$url" -o "$output"; then
        bashio::log.info "✅ Public download successful."
        return 0
    fi

    # 2. If failed, check if we have a token and try with it
    local exit_code=$?
    bashio::log.info "Public access failed (HTTP Code/Error: $exit_code). Checking for token..."

    if [ -n "$token" ]; then
        local auth_header=$(get_auth_header "$token")
        bashio::log.info "Token found. Retrying with authentication..."

        if curl -L -f -H "$auth_header" -H "Accept: application/vnd.github.v3+json" "$url" -o "$output"; then
            bashio::log.info "✅ Authenticated download successful."
            return 0
        else
            bashio::log.error "❌ Download failed even with token."
            return 1
        fi
    else
        bashio::log.error "❌ Public access failed and no 'github_token' is configured."
        bashio::log.error "If this is a private repository, please add a token in the configuration."
        return 1
    fi
}

# --- INITIAL CODE DOWNLOAD ---
# Check if code has been downloaded yet
if [ ! -f "/app/backend/main.py" ] || [ ! -f "/app/frontend/index.html" ]; then
    bashio::log.info "==================================================="
    bashio::log.info "   📦 INITIAL CODE DOWNLOAD REQUIRED"
    bashio::log.info "==================================================="
    bashio::log.info "This is the first start or code is missing."
    bashio::log.info "Attempting to download faneX-ID core..."

    # Get GitHub Token from config (optional)
    GITHUB_TOKEN=""
    if bashio::config.has_value 'github_token' && [ -n "$(bashio::config 'github_token')" ]; then
        GITHUB_TOKEN=$(bashio::config 'github_token')
        bashio::log.debug "GitHub Token is configured."
    else
        bashio::log.debug "No GitHub Token configured."
    fi

    # Determine version to download
    DOWNLOAD_VERSION="$VERSION"

    if [ "$DOWNLOAD_VERSION" == "latest" ]; then
        bashio::log.info "Fetching latest release information..."

        # We need to fetch the tag name. Logic similar to download: try public, then private.
        LATEST_RELEASE_TAG=""

        # Try public API
        LATEST_RELEASE_JSON=$(curl -s -f https://api.github.com/repos/fanex-id/core/releases/latest)

        if [ $? -eq 0 ]; then
             LATEST_RELEASE_TAG=$(echo "$LATEST_RELEASE_JSON" | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')
        elif [ -n "$GITHUB_TOKEN" ]; then
             bashio::log.info "Public release check failed. Trying with token..."
             AUTH_HEADER=$(get_auth_header "$GITHUB_TOKEN")
             LATEST_RELEASE_JSON=$(curl -s -f -H "$AUTH_HEADER" https://api.github.com/repos/fanex-id/core/releases/latest)
             if [ $? -eq 0 ]; then
                 LATEST_RELEASE_TAG=$(echo "$LATEST_RELEASE_JSON" | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')
             fi
        fi

        if [ -n "$LATEST_RELEASE_TAG" ]; then
            DOWNLOAD_VERSION="$LATEST_RELEASE_TAG"
            bashio::log.info "Latest release identified: $DOWNLOAD_VERSION"
        else
            bashio::log.warning "Could not identify latest release. Defaulting to 'main' branch."
            DOWNLOAD_VERSION="main"
        fi
    fi

    # Prepare Download URL
    if [ "$DOWNLOAD_VERSION" == "main" ]; then
        DOWNLOAD_URL="https://api.github.com/repos/fanex-id/core/tarball/main"
    else
        DOWNLOAD_URL="https://api.github.com/repos/fanex-id/core/tarball/$DOWNLOAD_VERSION"
    fi

    # Download
    cd /tmp || exit 1
    if download_file "$DOWNLOAD_URL" "fanexid.tar.gz" "$GITHUB_TOKEN"; then
        bashio::log.info "Extracting..."
        rm -rf /tmp/fanexid-src
        mkdir -p /tmp/fanexid-src
        tar -xzf fanexid.tar.gz -C /tmp/fanexid-src --strip-components=1

        # Install Backend
        bashio::log.info "Installing Backend..."
        if [ -d "/tmp/fanexid-src/backend" ]; then
            cp -r /tmp/fanexid-src/backend/* /app/backend/

            if [ -f "/app/backend/requirements.txt" ]; then
                bashio::log.info "Installing Python dependencies..."
                pip3 install --no-cache-dir -r /app/backend/requirements.txt || \
                    bashio::log.warning "Some Python dependencies failed to install"
            fi
        else
            bashio::log.error "Backend directory not found in repository!"
            exit 1
        fi

        # Build Frontend
        bashio::log.info "Building Frontend (this may take several minutes)..."
        if [ -d "/tmp/fanexid-src/frontend" ]; then
            cd /tmp/fanexid-src/frontend || exit 1

            bashio::log.info "Running 'npm install'..."
            if npm install; then
                bashio::log.info "Running 'npm run build'..."
                if npm run build; then
                    bashio::log.info "Frontend build successful. Installing..."
                    if [ -d "dist" ]; then
                        cp -r dist/* /app/frontend/
                    else
                        bashio::log.error "'dist' directory not found after build!"
                        exit 1
                    fi
                else
                    bashio::log.error "Frontend build failed!"
                    exit 1
                fi
            else
                bashio::log.error "npm install failed!"
                exit 1
            fi
        else
            bashio::log.error "Frontend directory not found in repository!"
            exit 1
        fi

        # Cleanup
        cd / || exit 1
        rm -rf /tmp/fanexid.tar.gz /tmp/fanexid-src

        bashio::log.info "==================================================="
        bashio::log.info "   ✅ CODE DOWNLOAD COMPLETE"
        bashio::log.info "==================================================="
    else
        bashio::log.error "Download failed! Please check your network or token settings."
        exit 1
    fi
fi

# --- DEV MODE: USE MAIN BRANCH ---
if bashio::config.true 'developer_mode'; then
    bashio::log.warning "=================================================="
    bashio::log.warning "   ⚠️  DEVELOPER MODE ENABLED  ⚠️"
    bashio::log.warning "=================================================="
    bashio::log.warning "Using latest code from 'main' branch."
    bashio::log.warning "Downloading and rebuilding..."

    # Get GitHub Token (Optional)
    GITHUB_TOKEN=""
    if bashio::config.has_value 'github_token' && [ -n "$(bashio::config 'github_token')" ]; then
        GITHUB_TOKEN=$(bashio::config 'github_token')
    fi

    # Download main branch with fallback
    cd /tmp || exit 1
    DOWNLOAD_URL="https://api.github.com/repos/fanex-id/core/tarball/main"

    if download_file "$DOWNLOAD_URL" "main.tar.gz" "$GITHUB_TOKEN"; then
        bashio::log.info "Extracting..."
        rm -rf /tmp/fanexid-main
        mkdir -p /tmp/fanexid-main
        tar -xzf main.tar.gz -C /tmp/fanexid-main --strip-components=1

        # Update Backend
        bashio::log.info "Updating Backend code..."
        if [ -d "/tmp/fanexid-main/backend" ]; then
            cp -r /tmp/fanexid-main/backend/* /app/backend/

            # Install potentially new python requirements
            if [ -f "/app/backend/requirements.txt" ]; then
                bashio::log.info "Installing Python dependencies..."
                pip3 install --no-cache-dir -r /app/backend/requirements.txt
            fi
        else
            bashio::log.error "Backend directory not found in main branch!"
        fi

        # Rebuild Frontend
        bashio::log.info "Rebuilding Frontend..."
        if [ -d "/tmp/fanexid-main/frontend" ]; then
            # Create temp build dir
            rm -rf /tmp/frontend_build
            mkdir -p /tmp/frontend_build
            cp -r /tmp/fanexid-main/frontend/* /tmp/frontend_build/

            cd /tmp/frontend_build || exit 1

            bashio::log.info "Running 'npm install'..."
            if npm install; then
                bashio::log.info "Running 'npm run build'..."
                if npm run build; then
                    bashio::log.info "Frontend build successful. Updating files..."
                    # Remove old frontend files
                    rm -rf /app/frontend/*
                    if [ -d "dist" ]; then
                        cp -r dist/* /app/frontend/
                    else
                        bashio::log.error "'dist' directory not found after build!"
                    fi
                else
                    bashio::log.error "Frontend build failed! Keeping old frontend."
                fi
            else
                bashio::log.error "npm install failed! Keeping old frontend."
            fi
        else
            bashio::log.error "Frontend directory not found in main branch!"
        fi

        # Cleanup
        rm -rf /tmp/main.tar.gz /tmp/fanexid-main /tmp/frontend_build
        cd / || exit 1

        bashio::log.info "=================================================="
        bashio::log.info "   ✅ DEV MODE UPDATE COMPLETE"
        bashio::log.info "=================================================="
    else
        bashio::log.error "Failed to download main branch from GitHub!"
    fi
else
    bashio::log.info "Production Mode: Using existing/packaged version."
fi

# --- SETUP SYMLINKS FOR PERSISTENCE ---
bashio::log.info "Setting up persistent storage..."

# Link uploads directory
mkdir -p /app/backend/static
rm -rf /app/backend/static/uploads
ln -s "$UPLOADS_DIR" /app/backend/static/uploads

# Link plugins directory
rm -rf /app/plugins
ln -s "$PLUGINS_DIR" /app/plugins

# --- DATABASE MIGRATIONS ---
if [ -f "/app/backend/alembic.ini" ]; then
    bashio::log.info "Running database migrations..."
    cd /app/backend || exit 1
    alembic upgrade head || bashio::log.warning "Migration failed or not needed, continuing..."
fi

# --- BACKEND START ---
bashio::log.info "Starting faneX-ID Backend (Uvicorn)..."
bashio::log.info "Environment: DEBUG=$DEBUG, DEMO_MODE=$DEMO_MODE, LOG_LEVEL=${LOG_LEVEL:-INFO}"
cd /app/backend || exit 1

# Set Python path
export PYTHONPATH=/app/backend

# Start Uvicorn in background
uvicorn main:app --host 127.0.0.1 --port 8001 --log-level "$(echo $LOG_LEVEL | tr '[:upper:]' '[:lower:]')" &
BACKEND_PID=$!

# --- NGINX START ---
bashio::log.info "Starting Nginx (Frontend)..."
mkdir -p /run/nginx
nginx -g "daemon off;" &
NGINX_PID=$!

bashio::log.info "faneX-ID is now running!"
bashio::log.info "Access via Home Assistant Ingress"

# Trap signals to stop processes correctly
cleanup() {
    bashio::log.info "Shutting down services..."

    # Stop Nginx gracefully
    kill -TERM $NGINX_PID 2>/dev/null
    wait $NGINX_PID 2>/dev/null

    # Stop Backend gracefully
    kill -TERM $BACKEND_PID 2>/dev/null
    wait $BACKEND_PID 2>/dev/null

    bashio::log.info "All services stopped"
    exit 0
}

trap cleanup SIGTERM SIGHUP

wait $NGINX_PID