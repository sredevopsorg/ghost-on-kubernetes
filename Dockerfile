# This Dockerfile is used to build a container image for running Ghost, a popular open-source blogging platform, on Kubernetes.
# The image is built with official Node 20 on Debian Bookworm (LTS Iron)  image and uses the Distroless base image for security and minimalism.

# Stage 1: Build Environment
FROM node:iron-bookworm@sha256:786005cf39792f7046bcd66491056c26d2dbcc669c072d1a1e4ef4fcdddd26eb AS build-env

ENV NODE_ENV=production  NPM_CONFIG_LOGLEVEL=info

# Update sources and install libvips to build some dependencies later

# USER root
# RUN apt update && apt install --no-install-recommends --no-install-suggests -y libvips-dev 
USER node

# Install the latest version of Ghost CLI globally and config some workarounds to build arm64 version in Github without timeout failures
RUN yarn config set network-timeout 60000 && \
    yarn config set inline-builds true && \
    npm config set fetch-timeout 60000 && \
    npm config set progress && \
    npm config set omit dev

RUN	yarn global add ghost-cli@latest

# Define the GHOST_VERSION build argument and set it as an environment variable
ARG GHOST_VERSION 
ENV GHOST_VERSION=$GHOST_VERSION  

# Set the installation directory, content directory, and original content directory for Ghost
ENV GHOST_INSTALL=/home/node/app/ghost
ENV GHOST_CONTENT=/home/node/app/ghost/content
ENV GHOST_CONTENT_ORIGINAL=/home/node/app/ghost/content.orig

# Create the Ghost installation directory and set the owner to the "node" user
RUN mkdir -pv "$GHOST_INSTALL" && \
    chown node:node "$GHOST_INSTALL"

# Switch to the "node" user
# USER node
# Workarounds to build arm64 version in Github without timeout failures
RUN yarn config set network-timeout 180000 && \
    npm config set fetch-timeout 180000
  #yarn config set inline-builds true && \
  #npm config set progress && \
  #npm config set omit dev

# Install Ghost with the specified version, using MySQL as the database, and configure it without prompts, stack traces, setup, and in the specified installation directory
RUN ghost install $GHOST_VERSION --dir $GHOST_INSTALL --db mysql --dbhost mysql --no-prompt --no-stack --no-setup --color --process local

# Switch back to the root user
#USER root

# Move the original content directory to a backup location, create a new content directory, set the correct ownership and permissions, and switch back to the "node" user
RUN mv -v $GHOST_CONTENT $GHOST_CONTENT_ORIGINAL && \
    mkdir -v $GHOST_CONTENT && \
    chown -Rfv node:node $GHOST_CONTENT_ORIGINAL && \
    chown -Rfv node:node $GHOST_CONTENT && \
    chown -fv node:node $GHOST_INSTALL && \
    chmod -v 1775 $GHOST_CONTENT

# Switch back to the "node" user
# USER node

# Stage 2: Final Image
FROM gcr.io/distroless/nodejs20-debian12@sha256:08d0b6846a21812d07a537eff956acc1bc38a7440a838ce6730515f8d3cd5d9e AS runtime

# Set the installation directory and content directory for Ghost
ENV GHOST_INSTALL=/home/node/app/ghost
ENV GHOST_CONTENT=/home/node/app/ghost/content
ENV GHOST_CONTENT_ORIGINAL=/home/node/app/ghost/content.orig

USER node

# Copy the Ghost installation directory from the build environment to the final image
COPY --from=build-env $GHOST_INSTALL $GHOST_INSTALL

# Set the working directory to the Ghost installation directory and create a volume for the content directory
# The volume is used to persist the data across container restarts, upgrades, and migrations. 
# It's going to be handled with an init container that will copy the content from your original content directory to the new content directory (If there is any)
# The CMD script will handle default themes included (Casper and Source) and init Ghost.

WORKDIR $GHOST_INSTALL
VOLUME $GHOST_CONTENT

# Copy the entrypoint script to the current Ghost version.
COPY --chown=1000:1000 entrypoint.js current/entrypoint.js


# Expose port 2368 for Ghost
EXPOSE 2368

# Set the command to start Ghost with the entrypoint (See https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/entrypoint.js)
CMD ["current/entrypoint.js"]
