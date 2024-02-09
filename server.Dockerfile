FROM node:18-alpine3.19 as base_builder

WORKDIR /usr/src/app

ENV HOPP_ALLOW_RUNTIME_ENV=true

RUN npm install -g pnpm
COPY pnpm-lock.yaml .
RUN pnpm fetch

COPY . .
RUN pnpm install -f --offline

FROM base_builder as backend
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