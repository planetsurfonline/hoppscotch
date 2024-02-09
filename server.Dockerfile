FROM node:18-alpine3.19 as base_builder

WORKDIR /usr/src/app

ENV HOPP_ALLOW_RUNTIME_ENV=true

RUN npm install -g pnpm
COPY pnpm-lock.yaml .
RUN pnpm fetch

COPY . .
RUN pnpm install -f --offline

FROM base_builder as backend

ARG DATABASE_URL
ARG JWT_SECRET
ARG TOKEN_SALT_COMPLEXITY
ARG MAGIC_LINK_TOKEN_VALIDITY
ARG REFRESH_TOKEN_VALIDITY
ARG ACCESS_TOKEN_VALIDITY
ARG SESSION_SECRET
ARG REDIRECT_URL
ARG WHITELISTED_ORIGINS
ARG VITE_ALLOWED_AUTH_PROVIDERS
ARG GOOGLE_CLIENT_ID
ARG GOOGLE_CLIENT_SECRET
ARG GOOGLE_CALLBACK_URL
ARG GOOGLE_SCOPE
ARG GITHUB_CLIENT_ID
ARG GITHUB_CLIENT_SECRET
ARG GITHUB_CALLBACK_URL
ARG GITHUB_SCOPE
ARG MICROSOFT_CLIENT_ID
ARG MICROSOFT_CLIENT_SECRET
ARG MICROSOFT_CALLBACK_URL
ARG MICROSOFT_SCOPE
ARG MICROSOFT_TENANT
ARG MAILER_SMTP_URL
ARG MAILER_ADDRESS_FROM
ARG RATE_LIMIT_TTL
ARG RATE_LIMIT_MAX

RUN apk add caddy
WORKDIR /usr/src/app/packages/hoppscotch-backend
RUN pnpm exec prisma generate
RUN pnpm run build
COPY --from=base_builder /usr/src/app/packages/hoppscotch-backend/backend.Caddyfile /etc/caddy/backend.Caddyfile
# Remove the env file to avoid backend copying it in and using it
RUN rm "../../.env"
# ENV PRODUCTION="true"
# ENV PORT=8080
# ENV APP_PORT=${PORT}
# ENV DB_URL=${DATABASE_URL}
CMD ["node", "/usr/src/app/packages/hoppscotch-backend/prod_run.mjs"]
EXPOSE 80
EXPOSE 3170