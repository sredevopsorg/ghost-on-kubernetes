FROM node:hydrogen-slim

LABEL org.opencontainers.image.description 'Ghost CMS v5 (latest release from @TryGhost) by SREDevOps.org (@sredevopsorg) on node hydrogen-bookworm-slim, no gosu, updated npm and ghost-cli'

ENV DEBIAN_FRONTEND noninteractive

#RUN apt-get update && apt-get upgrade --no-install-recommends -y && \
#    apt-get install --no-install-recommends -y ca-certificates && apt-get autoclean -y && apt-get autoremove -y 

ENV NODE_ENV production 

# RUN npm install -g "npm@latest" && \
RUN npm install -g "ghost-cli@latest" && \
    npm cache clean --force || true && \
    yarn cache clean || true

ARG GHOST_VERSION
ENV GHOST_VERSION $GHOST_VERSION 

ENV GHOST_INSTALL /var/lib/ghost
ENV GHOST_CONTENT /var/lib/ghost/content

RUN mkdir -p "$GHOST_INSTALL" && \
    chown node:node "$GHOST_INSTALL" && \
    mkdir -p "$GHOST_CONTENT" && \
    chown node:node "$GHOST_CONTENT" && \
    chmod 1777 "$GHOST_CONTENT"

USER node
WORKDIR $GHOST_INSTALL

RUN rm -Rf "$GHOST_INSTALL"/* && \
    ghost install "$GHOST_VERSION" --db mysql --dbhost mysql --no-prompt --no-stack --no-setup --dir "$GHOST_INSTALL" 

RUN ghost config --no-prompt --ip '::' --port 2368 --url 'http://localhost:2368' && \
    ghost config paths.contentPath "$GHOST_CONTENT" && \
    ln -s config.production.json "$GHOST_INSTALL/config.development.json" && \
    readlink -f "$GHOST_INSTALL/config.development.json" 


USER root

RUN mv "$GHOST_CONTENT" "$GHOST_INSTALL/content.orig" && \
    mkdir -p "$GHOST_CONTENT" && \
    chown node:node "$GHOST_CONTENT" && \
    chmod 1777 "$GHOST_CONTENT"

USER node

WORKDIR $GHOST_INSTALL
VOLUME $GHOST_CONTENT

COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["entrypoint.sh"]

EXPOSE 2368
CMD ["node", "current/index.js"]
