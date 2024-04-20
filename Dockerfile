# This Dockerfile is used to build a container image for running Ghost, a popular open-source blogging platform, on Kubernetes.
# The image is based on the official Node.js image and uses the Distroless base image for security and minimalism.

# Stage 1: Build Environment
FROM node:iron-buster AS build-env

ENV NODE_ENV production
ENV DEBIAN_FRONTEND noninteractive


# Set the NODE_ENV environment variable to "production"
# ENV NODE_ENV production 
USER root

RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -y libvips-dev ca-certificates && \
    update-ca-certificates
# && \
#    rm -rf /var/lib/apt/lists/*

# Install the latest version of Ghost CLI globally and clean the npm cache
RUN yarn config set network-timeout 60000 && \
		npm config set fetch-timeout 60000 && \
		yarn global add ghost-cli@latest || npm install -g ghost-cli@latest
#RUN yarn cache clean --force && npm cache clean --force 

# Define the GHOST_VERSION build argument and set it as an environment variable
ARG GHOST_VERSION
ENV GHOST_VERSION $GHOST_VERSION 

# Set the installation directory, content directory, and original content directory for Ghost
ENV GHOST_INSTALL /var/lib/ghost
ENV GHOST_CONTENT /var/lib/ghost/content
ENV GHOST_CONTENT_ORIGINAL /var/lib/ghost/content.orig

# Create the Ghost installation directory and set the owner to the "node" user
RUN mkdir -pv "$GHOST_INSTALL" && \
    chown node:node "$GHOST_INSTALL"

# Switch to the "node" user and set the working directory to the home directory
USER node
# WORKDIR /home/node

# Install Ghost with the specified version, using MySQL as the database, and configure it without prompts, stack traces, setup, and in the specified installation directory
RUN yarn config set network-timeout 180000 && \
    yarn config set verbose true && \
    ghost install $GHOST_VERSION --db mysql --dbhost mysql --no-prompt --no-stack --no-setup --dir $GHOST_INSTALL

# Switch back to the root user
USER root

# Move the original content directory to a backup location, create a new content directory, set the correct ownership and permissions, and switch back to the "node" user
RUN mv -v $GHOST_CONTENT $GHOST_CONTENT_ORIGINAL && \
    mkdir -pv $GHOST_CONTENT && \
    chown -Rfv node:node $GHOST_CONTENT_ORIGINAL && \
    chown -Rfv node:node $GHOST_CONTENT && \
    chmod 1777 $GHOST_CONTENT

# Switch back to the "node" user
USER node

# Stage 2: Final Image
FROM gcr.io/distroless/nodejs20-debian12:latest

# Set the installation directory and content directory for Ghost
ENV GHOST_INSTALL /var/lib/ghost
ENV GHOST_CONTENT /var/lib/ghost/content

# Copy the Ghost installation directory from the build environment to the final image
COPY --from=build-env $GHOST_INSTALL $GHOST_INSTALL

# Set the working directory to the Ghost installation directory and create a volume for the content directory
# The volume is used to persist the data across container restarts, upgrades, and migrations. 
# It's going to be handled with an init container that will copy the content from the original content directory to the new content directory.
WORKDIR $GHOST_INSTALL
VOLUME $GHOST_CONTENT

# Expose port 2368 for Ghost
EXPOSE 2368

# Set the command to start Ghost
CMD ["current/index.js"]
