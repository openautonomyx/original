# syntax=docker/dockerfile:1.7

FROM node:22-alpine AS deps
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
ENV ASTRO_TELEMETRY_DISABLED=1
RUN corepack enable
WORKDIR /app

COPY package.json pnpm-workspace.yaml* ./
COPY apps ./apps
COPY packages ./packages
COPY pnpm-lock.yaml* ./
RUN pnpm install --no-frozen-lockfile

FROM deps AS build
RUN pnpm --filter @publishing-platform/web build

FROM node:22-alpine AS runner
ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=3000
WORKDIR /app
RUN addgroup -S nodejs && adduser -S astro -G nodejs
COPY --from=build --chown=astro:nodejs /app/apps/web/dist ./dist
COPY --from=build --chown=astro:nodejs /app/apps/web/package.json ./package.json
USER astro
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 CMD wget --spider -q http://127.0.0.1:3000/api/health || exit 1
CMD ["node", "./dist/server/entry.mjs"]
