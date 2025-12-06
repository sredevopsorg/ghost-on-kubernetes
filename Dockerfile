# This Dockerfile is used to build a container image for running Ghost, a popular open-source blogging platform, on Kubernetes.
# The image is built with official Node 22 on Debian Bookworm (LTS Jod)  image and uses the Distroless base image for security and minimalism.

# Stage 1: Build Environment
FROM node:jod-trixie@sha256:aec3ef753e2800bcef6ebb3d6f86e1ec0bb62b149b30881d04fa8ed2b00f5b6e AS build-env
USER root
# Create a new user and group named "nonroot" with the UID 65532 and GID 65532, not a member of the root, sudo, and sys groups, and set the home directory to /home/nonroot.
# This user is used to run the Ghost application in the container for security reasons.
RUN groupadd -g 65532 nonroot && \
    useradd -u 65532 -g 65532 -d /home/nonroot nonroot && \
    usermod -aG nonroot nonroot && \
    mkdir -pv /home/nonroot && \
    chown -Rfv 65532:65532 /home/nonroot

USER nonroot
SHELL ["/bin/bash", "-c"]
ENV NODE_ENV=production

# Define the GHOST_VERSION build argument and set it as an environment variable
ARG GHOST_VERSION 
ENV GHOST_VERSION=$GHOST_VERSION  

# Set the installation directory, content directory, and original content directory for Ghost
ENV GHOST_INSTALL=/home/nonroot/app/ghost
ENV GHOST_CONTENT=/home/nonroot/app/ghost/content
ENV GHOST_CONTENT_ORIGINAL=/home/nonroot/app/ghost/content.orig

RUN mkdir -pv "$GHOST_INSTALL"

# Install the latest version of Ghost CLI globally and config some workarounds to build arm64 version in Github without timeout failures
RUN yarn config set network-timeout 60000 && \
    yarn config set inline-builds true && \
    npm config set fetch-timeout 60000 && \
    npm config set omit dev && \
    export NODE_ENV=production && \
    npx ghost-cli install $GHOST_VERSION --dir $GHOST_INSTALL --db mysql --dbhost mysql --no-prompt --no-stack --no-setup --color --process local

# Move the original content directory to a backup location, create a new content directory, set the correct ownership and permissions, and switch back to the "node" user
RUN mv -v $GHOST_CONTENT $GHOST_CONTENT_ORIGINAL && \
    mkdir -v $GHOST_CONTENT && \
    chown -Rfv 65532 $GHOST_CONTENT_ORIGINAL && \
    chown -Rfv 65532 $GHOST_CONTENT && \
    chown -fv 65532 $GHOST_INSTALL && \
    chmod -v 1755 $GHOST_CONTENT

# Stage 2: Final Image
FROM gcr.io/distroless/nodejs22-debian13:latest@sha256:5c65bac666660d114d2d7588e39333e92b4a1685ba66bdf3c6faaedab2b4be6e AS runtime 

# Set the installation directory and content directory for Ghost
ENV GHOST_INSTALL_SRC=/home/nonroot/app/ghost
ENV GHOST_INSTALL=/home/nonroot/app/ghost
ENV GHOST_CONTENT=/home/nonroot/app/ghost/content
ENV GHOST_CONTENT_ORIGINAL=/home/nonroot/app/ghost/content.orig
ENV NODE_ENV=production
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
