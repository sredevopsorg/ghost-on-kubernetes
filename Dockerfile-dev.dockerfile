# This Dockerfile is used to build a container image for running Ghost, a popular open-source blogging platform, on Kubernetes.
# The image is built with official Node 24 on Debian Trixie (LTS) image and uses the Distroless base image for security and minimalism.
#
# Ghost is installed from the official GitHub release tarball rather than via `npx ghost-cli install`.
# Ghost-CLI is deprecated as of the Ghost 7.0 platform update (6.x is the last line that uses it), so the
# install path below mirrors the upstream `6-next` methodology instead:
#   * the exact release artifact and its SHA-256 are pinned, so a rebuild cannot pick up a different tarball
#     than the one that was reviewed,
#   * dependencies come from Ghost's own pruned lockfile (--frozen-lockfile), so the tree is installed
#     exactly rather than re-solved per build,
#   * Ghost's own pruner drops development TypeScript, sourcemaps, READMEs and vendored C/C++.
#
# The distroless runtime, the non-root UID 65532, the install paths and the Secret-mounted configuration are
# deliberate and differ from upstream's image: this image targets Kubernetes, where the content volume is a
# PVC, ownership is handled by an init container, and credentials must never live in an image layer.
#
# Stage 1: Build Environment
FROM docker.io/node:24-trixie@sha256:016f604a11c4c725f0a4c62e29ff11adab153d297bf97046c9bf2ddb9f1011d3 AS build-env
USER root
# Create a new user and group named "nonroot" with the UID 65532 and GID 65532, not a member of the root, sudo, and sys groups, and set the home directory to /home/nonroot.
# This user is used to run the Ghost application in the container for security reasons.
RUN groupadd -g 65532 nonroot && \
    useradd -u 65532 -g 65532 -d /home/nonroot nonroot && \
    usermod -aG nonroot nonroot && \
    mkdir -pv /home/nonroot && \
    chown -Rfv 65532:65532 /home/nonroot

ENV NODE_ENV=development

# Set the installation directory, content directory, and original content directory for Ghost
ENV GHOST_INSTALL=/home/nonroot/app/ghost
ENV GHOST_CONTENT=/home/nonroot/app/ghost/content
ENV GHOST_CONTENT_ORIGINAL=/home/nonroot/app/ghost/content.orig

# Define the Ghost version and the release artifact to install.
# The tarball URL and its SHA-256 are pinned together: the checksum is verified during the build below, so a
# build cannot silently install a different artifact than the one that was reviewed.
# These assets exist for Ghost 6.60.0 and later. When bumping the version, update all three values together
# (the digest is published on the GitHub release as "digest": "sha256:...").
ARG GHOST_VERSION
ENV GHOST_VERSION=$GHOST_VERSION
ENV GHOST_TARBALL_URL="https://github.com/TryGhost/Ghost/releases/download/v${GHOST_VERSION}/ghost-${GHOST_VERSION}.tgz"
ARG GHOST_TARBALL_SHA256
ENV GHOST_TARBALL_SHA256=$GHOST_TARBALL_SHA256

# Corepack installs the exact pnpm that Ghost pins in its "packageManager" field, so the package manager
# itself is version-locked by the tarball rather than by whatever is newest on the registry.
# This runs as root because "corepack enable" writes shims into the Node installation prefix.
RUN corepack enable

USER nonroot
RUN mkdir -pv "$GHOST_INSTALL"

# Keep corepack's and pnpm's caches out of the install directory: they are derived from these variables,
# and /tmp keeps them out of the layer that is copied into the final image.
ENV XDG_CACHE_HOME=/tmp/xdg-cache
ENV XDG_DATA_HOME=/tmp/xdg-data
WORKDIR "$GHOST_INSTALL"

# Download the release tarball and verify it against the pinned digest before anything is unpacked.
RUN curl -fsSL -o ghost.tgz "$GHOST_TARBALL_URL"
RUN echo "$GHOST_TARBALL_SHA256 ghost.tgz" | sha256sum -c -

# The release tarball has no leading "package/" component, unlike an npm pack, so it unpacks flat into
# the install directory. There is no "versions/" directory and no "current" symlink: the entrypoint and
# the CMD below are adjusted to match this layout.
RUN tar --extract --file ghost.tgz && \
    rm -fv ghost.tgz

# The tarball ships a pruned lockfile, so the tree is installed exactly as locked, not re-solved.
RUN pnpm install --prod --frozen-lockfile

# Install-time inputs only: package.json points a number of dependencies at "file:components/*.tgz", but
# pnpm extracts them into its virtual store and nothing resolves back here afterwards.
RUN rm -rf "$GHOST_INSTALL/components"

# Ghost's own pruner, as used by its development image: drops dependency TypeScript, sourcemaps, READMEs
# and vendored C/C++ (keeping licences and prebuilt .node). The tarball already has the "archive" profile
# applied, so this is mostly node_modules.
RUN node scripts/prune.mts "$GHOST_INSTALL" --profile=image

# Keep the initial content so the entrypoint can seed an empty volume with the bundled themes.
RUN mv "$GHOST_CONTENT" "$GHOST_CONTENT_ORIGINAL"
RUN mkdir -p "$GHOST_CONTENT"

RUN rm -rf /tmp/xdg-cache /tmp/xdg-data
RUN npm cache clean --force

# Fail the build rather than the pod: assert that the optional native dependencies are installed and load.
RUN node -e 'require("better-sqlite3"); if (!require("@tryghost/image-transform").canTransformFiles()) throw new Error("sharp not installed");'

# Stage 2: Final Image
FROM gcr.io/distroless/nodejs24-debian13:debug-nonroot@sha256:54fdff6ae698f05abb702d8e56cc03dca3426df7f3b992c25dba3f9cc2a50c5a AS runtime 

# Set the installation directory and content directory for Ghost
ENV GHOST_INSTALL_SRC=/home/nonroot/app/ghost
ENV GHOST_INSTALL=/home/nonroot/app/ghost
ENV GHOST_CONTENT=/home/nonroot/app/ghost/content
ENV GHOST_CONTENT_ORIGINAL=/home/nonroot/app/ghost/content.orig
ENV NODE_ENV=development
USER nonroot

# Copy the Ghost installation directory from the build environment to the final image
COPY --from=build-env $GHOST_INSTALL_SRC $GHOST_INSTALL

# Set the working directory to the Ghost installation directory.
# The content directory is a mount point in Kubernetes (a PVC), so it is not declared with VOLUME here: an
# implicit anonymous volume would be created for any plain "docker run" and could mask a missing -v.
WORKDIR $GHOST_INSTALL

# Copy the entrypoint script to the current Ghost version.
# Note the flat layout: the tarball unpacks directly into the install directory, so there is no "current"
# subdirectory to copy into and the entrypoint resolves Ghost's entry point relative to the install root.
COPY --chown=65532 entrypoint.js entrypoint.js

# Expose port 2368 for Ghost
EXPOSE 2368

# Set the command to start Ghost with the entrypoint (See https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/entrypoint.js)
# The distroless Node image's ENTRYPOINT is already /nodejs/bin/node, so CMD must be the script path only.
CMD ["entrypoint.js"]
