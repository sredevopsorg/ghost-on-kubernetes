# This Dockerfile is used to build a container image for running Ghost, a popular open-source blogging platform, on Kubernetes.
# The image is built with official Node 20 on Debian Bookworm (LTS Iron)  image and uses the Distroless base image for security and minimalism.

# Stage 1: Build Environment
FROM node:iron-bookworm@sha256:786005cf39792f7046bcd66491056c26d2dbcc669c072d1a1e4ef4fcdddd26eb AS build-env

USER node
SHELL ["/bin/bash", "-c"]
ENV NODE_ENV=production NPM_CONFIG_LOGLEVEL=info

# Define the GHOST_VERSION build argument and set it as an environment variable
ARG GHOST_VERSION 
ENV GHOST_VERSION=$GHOST_VERSION  

# Set the installation directory, content directory, and original content directory for Ghost
ENV GHOST_INSTALL=/home/nonroot/app/ghost
ENV GHOST_CONTENT=/home/nonroot/app/ghost/content
ENV GHOST_CONTENT_ORIGINAL=/home/nonroot/app/ghost/content.orig

RUN mkdir -pv "$GHOST_INSTALL" || sudo mkdir -pv "$GHOST_INSTALL" && \
    chown -Rfv 65532:65532 "$GHOST_INSTALL" || sudo chown -Rfv nonroot:nonroot "$GHOST_INSTALL"

# Install the latest version of Ghost CLI globally and config some workarounds to build arm64 version in Github without timeout failures
RUN yarn config set network-timeout 60000 && \
    yarn config set inline-builds true && \
    npm config set fetch-timeout 60000 && \
    npm config set progress && \
    npm config set omit dev

# Create the Ghost installation directory and set the owner to the "node" user


# RUN	npm i -g ghost-cli@latest || yarn global add ghost-cli@latest

# Install Ghost with the specified version, using MySQL as the database, and configure it without prompts, stack traces, setup, and in the specified installation directory
# RUN ghost install $GHOST_VERSION --dir $GHOST_INSTALL --db mysql --dbhost mysql --no-prompt --no-stack --no-setup --color --process local || 

RUN npx ghost-cli install $GHOST_VERSION --dir $GHOST_INSTALL --db mysql --dbhost mysql --no-prompt --no-stack --no-setup --color --process local


# Move the original content directory to a backup location, create a new content directory, set the correct ownership and permissions, and switch back to the "node" user
RUN mv -v $GHOST_CONTENT $GHOST_CONTENT_ORIGINAL && \
    mkdir -v $GHOST_CONTENT && \
    chown -Rfv nonroot:nobody $GHOST_CONTENT_ORIGINAL && \
    chown -Rfv nonroot:nobody $GHOST_CONTENT && \
    chown -fv nonroot:nobody $GHOST_INSTALL && \
    chmod -v 0775 $GHOST_CONTENT

# Switch back to the "node" user
# USER node

# Stage 2: Final Image
FROM gcr.io/distroless/nodejs20-debian12:nonroot

# Set the installation directory and content directory for Ghost
ENV GHOST_INSTALL_SRC=/home/nonroot/app/ghost
ENV GHOST_INSTALL=/home/nonroot/app/ghost
ENV GHOST_CONTENT=/home/nonroot/app/ghost/content
ENV GHOST_CONTENT_ORIGINAL=/home/nonroot/app/ghost/content.orig

USER nonroot

# Copy the Ghost installation directory from the build environment to the final image
COPY --from=build-env $GHOST_INSTALL_SRC $GHOST_INSTALL

# Set the working directory to the Ghost installation directory and create a volume for the content directory
# The volume is used to persist the data across container restarts, upgrades, and migrations. 
# It's going to be handled with an init container that will copy the content from your original content directory to the new content directory (If there is any)
# The CMD script will handle default themes included (Casper and Source) and init Ghost.

WORKDIR $GHOST_INSTALL
VOLUME $GHOST_CONTENT

# Copy the entrypoint script to the current Ghost version.
COPY --chown=65532 entrypoint.js current/entrypoint.js


# Expose port 2368 for Ghost
EXPOSE 2368

# Set the command to start Ghost with the entrypoint (See https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/entrypoint.js)
CMD ["current/entrypoint.js"]
