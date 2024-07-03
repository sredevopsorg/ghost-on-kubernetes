# This Dockerfile is used to build a container image for running Ghost, a popular open-source blogging platform, on Kubernetes.
# The image is built with official Node 20 on Debian Bookworm (LTS Iron)  image and uses the Distroless base image for security and minimalism.

# Stage 1: Build Environment
FROM node:iron-bookworm@sha256:93d2e801dabc677ea0b30b47d3d729fab63ecb20be7ac0ab204cc3c65731297a AS build-env

ENV NODE_ENV=production DEBIAN_FRONTEND=noninteractive

# Update sources and install libvips to build some dependencies later

USER root
RUN apt update && apt install --no-install-recommends --no-install-suggests -y libvips-dev 

# Install the latest version of Ghost CLI globally and config some workarounds to build arm64 version in Github without timeout failures
RUN yarn config set network-timeout 60000 && \
    yarn config set inline-builds true && \
		npm config set fetch-timeout 60000 && \
    npm config set progress && \
    npm config set omit dev

RUN	yarn global add ghost-cli@latest

# Define the GHOST_VERSION build argument and set it as an environment variable
ARG GHOST_VERSION
ENV GHOST_VERSION $GHOST_VERSION 

# Set the installation directory, content directory, and original content directory for Ghost
ENV GHOST_INSTALL=/var/lib/ghost
ENV GHOST_CONTENT=/var/lib/ghost/content
ENV GHOST_CONTENT_ORIGINAL=/var/lib/ghost/content.orig

# Create the Ghost installation directory and set the owner to the "node" user
RUN mkdir -pv "$GHOST_INSTALL" && \
    chown node:node "$GHOST_INSTALL"

# Switch to the "node" user
USER node
# Workarounds to build arm64 version in Github without timeout failures
RUN yarn config set network-timeout 180000 && \
  yarn config set inline-builds true && \
  npm config set fetch-timeout 180000 && \
  npm config set progress && \
  npm config set omit dev

# Install Ghost with the specified version, using MySQL as the database, and configure it without prompts, stack traces, setup, and in the specified installation directory
RUN ghost install $GHOST_VERSION --dir $GHOST_INSTALL --db mysql --dbhost mysql --no-prompt --no-stack --no-setup --color --process local

# Switch back to the root user
USER root

# Move the original content directory to a backup location, create a new content directory, set the correct ownership and permissions, and switch back to the "node" user
RUN mv -v $GHOST_CONTENT $GHOST_CONTENT_ORIGINAL && \
    mkdir -pv $GHOST_CONTENT && \
    chown -Rfv node:node $GHOST_CONTENT_ORIGINAL && \
    chown -Rfv node:node $GHOST_CONTENT && \
    chown -fv node:node $GHOST_INSTALL && \
    chmod 1775 $GHOST_CONTENT

# Switch back to the "node" user
USER node

# Stage 2: Final Image
FROM gcr.io/distroless/nodejs20-debian12@sha256:ddf825cbf6087b1ad1eca2cf64e3b40715d757fc8c59241cb31676245c2e3c4c AS runtime

# Set the installation directory and content directory for Ghost
ENV GHOST_INSTALL=/var/lib/ghost
ENV GHOST_CONTENT=/var/lib/ghost/content
ENV GHOST_CONTENT_ORIGINAL=/var/lib/ghost/content.orig

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

# Set the command to start Ghost
CMD ["current/entrypoint.js"]
