# Build context is the repo root (see infra/docker-compose.yml's "full"
# profile, or `docker build -f apps/api/Dockerfile .` from the repo root) —
# the API's install depends on the root npm-workspaces lockfile, which covers
# apps/admin and packages/contracts too even though the API doesn't import
# them at runtime.

FROM node:20-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
COPY apps/api/package.json apps/api/package.json
COPY apps/admin/package.json apps/admin/package.json
COPY packages/contracts/package.json packages/contracts/package.json
RUN npm ci
COPY apps/api apps/api
RUN npm run build --workspace apps/api

FROM node:20-alpine AS runtime
ENV NODE_ENV=production
WORKDIR /app
COPY package.json package-lock.json ./
COPY apps/api/package.json apps/api/package.json
COPY apps/admin/package.json apps/admin/package.json
COPY packages/contracts/package.json packages/contracts/package.json
RUN npm ci --omit=dev
COPY --from=build /app/apps/api/dist apps/api/dist

# Uploaded catalog-item photos (AdminUploadsController) — mount a volume
# here in any deployment where the container filesystem doesn't survive
# restarts/redeploys (see infra/docker-compose.yml's uploads-data volume).
RUN mkdir -p /app/apps/api/uploads && chown -R node:node /app/apps/api/uploads
USER node

WORKDIR /app/apps/api
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/v1/health || exit 1

CMD ["node", "dist/main.js"]
