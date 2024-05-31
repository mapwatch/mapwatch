# Build a node-based static site
FROM node:20 AS build

WORKDIR /app/packages/www
COPY packages/www/package.json ./
WORKDIR /app/packages/rss
COPY packages/rss/package.json ./
# WORKDIR /app/packages/datamine2
# COPY packages/datamine2/package.json ./
WORKDIR /app
COPY package.json yarn.lock lerna.json ./
RUN yarn --frozen-lockfile

# `.dockerignore` is important to cache this copy properly
# note, `packages/electron2` is a big one excluded there
WORKDIR /app
COPY . ./
RUN yarn test
RUN yarn build:www

# Run the static site we just built. No Caddyfile or other config, just static files.
# "The default config file simply serves files from /usr/share/caddy" - https://hub.docker.com/_/caddy
FROM caddy:2.8
COPY --from=build /app/packages/www/build/ /usr/share/caddy