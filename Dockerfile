# This Dockerfile is used to build a container image for running Ghost, a popular open-source blogging platform, on Kubernetes.
# The image is based on the official Node.js image and uses the Distroless base image for security and minimalism.

# Stage 1: Build Environment
FROM node:hydrogen-slim AS build-env


# Set the NODE_ENV environment variable to "production"
# ENV NODE_ENV production 
USER root

RUN apt-get update && apt-get install --no-install-recommends -y g++ make python3 && \
    rm -rf /var/lib/apt/lists/*

# Install the latest version of Ghost CLI globally and clean the npm cache
RUN yarn config set network-timeout 180000 && yarn global add ghost-cli@v1.26.0
RUN yarn cache clean --force && npm cache clean --force 


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
ENV NODE_ENV production
# WORKDIR /home/node

# Install Ghost with the specified version, using MySQL as the database, and configure it without prompts, stack traces, setup, and in the specified installation directory
# RUN yarn config set network-timeout 180000 || true && \
#     ghost install $GHOST_VERSION --db mysql --dbhost mysql --no-prompt --no-stack --no-setup --dir $GHOST_INSTALL

RUN set -eux; \
  installCmd='yarn config set network-timeout 180000 && ghost install "$GHOST_VERSION" --db mysql --dbhost mysql --no-prompt --no-stack --no-setup --dir "$GHOST_INSTALL"'; \
	if ! eval "$installCmd"; then \
		eval "$installCmd"; \
	fi; \
# force install a few extra packages manually since they're "optional" dependencies
# (which means that if it fails to install, like on ARM/ppc64le/s390x, the failure will be silently ignored and thus turn into a runtime error instead)
# see https://github.com/TryGhost/Ghost/pull/7677 for more details
	cd "$GHOST_INSTALL/current"; \
# scrape the expected versions directly from Ghost/dependencies
	packages="$(node -p ' \
		var ghost = require("./package.json"); \
		var transform = require("./node_modules/@tryghost/image-transform/package.json"); \
		[ \
			"sharp@" + transform.optionalDependencies["sharp"], \
			"sqlite3@" + ghost.optionalDependencies["sqlite3"], \
		].join(" ") \
	')"; \
	if echo "$packages" | grep 'undefined'; then exit 1; fi; \
	for package in $packages; do \
		installCmd='yarn add "$package" --force'; \
		if ! eval "$installCmd"; then \
# must be some non-amd64 architecture pre-built binaries aren't published for, so let's install some build deps and do-it-all-over-again
			case "$package" in \
				# TODO sharp@*) apt-get install -y --no-install-recommends libvips-dev ;; \
				sharp@*) echo >&2 "sorry: libvips 8.10 in Debian bullseye is not new enough (8.12.2+) for sharp 0.30 😞"; continue ;; \
			esac; \
			\
			eval "$installCmd --build-from-source"; \
		fi; \
	done; \
	yarn cache clean; \
	npm cache clean --force;


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
FROM gcr.io/distroless/nodejs18-debian12:latest

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
