# https://docs.ghost.org/faq/node-versions/
# https://github.com/nodejs/Release (looking for "LTS")
# https://github.com/TryGhost/Ghost/blob/v4.1.2/package.json#L38
FROM node:18-bookworm-slim

ENV NODE_ENV production

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get upgrade -y 
RUN apt-get install -y --no-install-recommends g++ make python3 libvips-dev nano && apt-get clean && rm -rf /var/lib/apt/lists/*



# ENV GHOST_CLI_VERSION 1.24.1
RUN npm install -g "ghost-cli@latest" && npm cache clean --force

ENV GHOST_INSTALL /var/lib/ghost
ENV GHOST_CONTENT /var/lib/ghost/content

ARG GHOST_VERSION=5.55.1
ENV GHOST_VERSION $GHOST_VERSION 

RUN mkdir -pv "$GHOST_INSTALL" && \
    chown node:node -Rf "$GHOST_INSTALL" 

USER node
WORKDIR $GHOST_INSTALL

RUN ghost install "$GHOST_VERSION" --db mysql --dbhost mysql --no-prompt --no-stack --no-setup --dir "$GHOST_INSTALL" && \
    # Tell Ghost to listen on all ips and not prompt for additional configuration
	cd "$GHOST_INSTALL" && ghost config --no-prompt --ip '::' --port 2368 --url 'http://localhost:2368' && \
	ghost config paths.contentPath "$GHOST_CONTENT" 
# make a config.json symlink for NODE_ENV=development (and sanity check that it's correct)
RUN ln -s config.production.json "$GHOST_INSTALL/config.development.json" && \
	readlink -f "$GHOST_INSTALL/config.development.json" 
# need to save initial content for pre-seeding empty volumes
USER root
RUN	mv "$GHOST_CONTENT" "$GHOST_INSTALL/content.orig" && \
	mkdir -pv "$GHOST_CONTENT" && \
	chown node:node "$GHOST_CONTENT" && \
	chmod 1777 "$GHOST_CONTENT" && \
# force install a few extra packages manually since they're "optional" dependencies
# (which means that if it fails to install, like on ARM/ppc64le/s390x, the failure will be silently ignored and thus turn into a runtime error instead)
# see https://github.com/TryGhost/Ghost/pull/7677 for more details
	cd "$GHOST_INSTALL/current" && \ 
    yarn cache clean && \
	npm cache clean --force && \
	rm -rv /tmp/yarn* /tmp/v8*
COPY --chmod=0777 docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh && apt-get autoclean && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* 
USER node
WORKDIR $GHOST_INSTALL
VOLUME $GHOST_CONTENT

ENV PATH $PATH:/usr/local/bin:$GHOST_INSTALL/current/node_modules/.bin
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 2368
CMD ["node", "current/index.js"]
