FROM node:hydrogen-bookworm-slim AS build-env

ENV NODE_ENV production 

RUN npm install -g "ghost-cli@latest" && \
    npm cache clean --force

ARG GHOST_VERSION
ENV GHOST_VERSION $GHOST_VERSION 

ENV GHOST_INSTALL /var/lib/ghost
ENV GHOST_CONTENT /var/lib/ghost/content
ENV GHOST_CONTENT_ORIGINAL /var/lib/ghost/content.orig

RUN mkdir -pv "$GHOST_INSTALL" && \
    chown node:node "$GHOST_INSTALL"

USER node
WORKDIR /home/node

RUN ghost install $GHOST_VERSION --db mysql --dbhost mysql --no-prompt --no-stack --no-setup --dir $GHOST_INSTALL

WORKDIR $GHOST_INSTALL

RUN ghost config --no-prompt --ip '::' --port 2368 --url 'http://localhost:2368' && \
    ghost config paths.contentPath $GHOST_CONTENT && \
    ln -s config.production.json $GHOST_INSTALL/config.development.json && \
    readlink -f $GHOST_INSTALL/config.development.json 

USER root

RUN mv -v $GHOST_CONTENT $GHOST_CONTENT_ORIGINAL && \
    mkdir -pv $GHOST_CONTENT && \
    cp -R $GHOST_CONTENT_ORIGINAL/themes $GHOST_CONTENT/ && \
    chown node:node $GHOST_CONTENT && \
    chmod 1777 $GHOST_CONTENT

USER node

FROM gcr.io/distroless/nodejs18-debian12:latest

ENV GHOST_INSTALL /var/lib/ghost
ENV GHOST_CONTENT /var/lib/ghost/content

COPY --from=build-env $GHOST_INSTALL $GHOST_INSTALL

WORKDIR $GHOST_INSTALL
VOLUME $GHOST_CONTENT

EXPOSE 2368

CMD ["current/index.js"]
