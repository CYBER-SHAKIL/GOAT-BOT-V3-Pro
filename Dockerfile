FROM node:20-bookworm-slim

WORKDIR /app

# ── System dependencies for native Node modules ──────────────────────────────
# canvas: cairo, pango, libjpeg, giflib, librsvg, pixman
# bcrypt:  python3, build-essential
# sqlite3: python3, build-essential
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    python3 \
    python3-dev \
    python-is-python3 \
    pkg-config \
    curl \
    libcairo2-dev \
    libpango1.0-dev \
    libjpeg-dev \
    libgif-dev \
    librsvg2-dev \
    libpng-dev \
    libpixman-1-dev \
    libfontconfig-dev \
    fonts-liberation \
    fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*

# ── Install dependencies (layer-cached separately from source code) ───────────
COPY package.json ./
COPY scripts/patch-fca.js scripts/patch-fca.js
RUN npm install --legacy-peer-deps
COPY . .
# ── Copy source code ──────────────────────────────────────────────────────────
COPY . .

# ── Post-install setup ────────────────────────────────────────────────────────
RUN node scripts/patch-fca.js || true && \
    mkdir -p scripts/cmds/cache scripts/cmds/tmp scripts/events/tmp \
             scripts/events/data/leaveAttachment scripts/events/data/welcomeAttachment \
             database/data cache logs && \
    touch database/data/.gitkeep scripts/cmds/tmp/.gitkeep scripts/events/tmp/.gitkeep && \
    rm -f .instance.lock

# ── Runtime ───────────────────────────────────────────────────────────────────
# PORT is injected at runtime by Render/Railway/etc.
# index.js binds the health server to process.env.PORT || 3000
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
    CMD curl -f http://localhost:${PORT:-3000}/health || exit 1

CMD ["node", "index.js"]
