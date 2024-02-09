FROM node:18-alpine3.19 as base_builder

WORKDIR /usr/src/app

ENV HOPP_ALLOW_RUNTIME_ENV=true

RUN npm install -g pnpm
COPY pnpm-lock.yaml .
RUN pnpm fetch

COPY . .
RUN pnpm install -f

FROM base_builder as fe_builder
WORKDIR /usr/src/app/packages/hoppscotch-selfhost-web
RUN pnpm run generate

FROM caddy:2-alpine as app

ARG VITE_BASE_URL
ARG VITE_SHORTCODE_BASE_URL
ARG VITE_ADMIN_URL
ARG VITE_BACKEND_GQL_URL
ARG VITE_BACKEND_WS_URL
ARG VITE_BACKEND_API_URL
ARG VITE_APP_TOS_LINK
ARG VITE_APP_PRIVACY_POLICY_LINK
ARG ENABLE_SUBPATH_BASED_ACCESS

WORKDIR /site
COPY --from=fe_builder /usr/src/app/packages/hoppscotch-selfhost-web/prod_run.mjs /usr
COPY --from=fe_builder /usr/src/app/packages/hoppscotch-selfhost-web/selfhost-web.Caddyfile /etc/caddy/selfhost-web.Caddyfile
COPY --from=fe_builder /usr/src/app/packages/hoppscotch-selfhost-web/dist/ .
RUN apk add nodejs npm
RUN npm install -g @import-meta-env/cli
EXPOSE 80
EXPOSE 3000
CMD ["/bin/sh", "-c", "node /usr/prod_run.mjs && caddy run --config /etc/caddy/selfhost-web.Caddyfile --adapter caddyfile"]