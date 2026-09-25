# ==============================================================================
# Description: Build multi-stage de la app Angular (compilacion Node + runtime
#   nginx minimo no-root con healthcheck). Produce imagenes reproducibles con
#   labels OCI para trazabilidad (revision, fecha, version).
# Maintainer: nehemias salazar <nehemiassala@gmail.com>
# Usage: docker build --build-arg GIT_SHA=<sha> --build-arg BUILD_TAG=<tag> --build-arg BUILD_DATE=<iso8601> -f docker/Dockerfile docker/
# Env Vars: GIT_SHA (revision del commit), BUILD_TAG (tag de version), BUILD_DATE (fecha ISO-8601)
# Dependencies: Docker 24+, stage build node:22.18-alpine, stage runtime nginx:1.27-alpine
# ==============================================================================
ARG GIT_SHA=dev BUILD_TAG=dev BUILD_DATE=unknown

FROM node:22.18-alpine AS build

LABEL maintainer="nehemias salazar <nehemiassala@gmail.com>"

# Set the working directory
WORKDIR /app

# Copy the package.json and package-lock.json files (if they exist) into the container
COPY package*.json ./

# Install the dependencies from the 'package-lock.json' file.
RUN npm ci

# Copy the Angular application source code into the container
COPY . .

# Build the Angular application (this generates the files in dist/)
RUN npx ng build

FROM nginx:1.27-alpine

ARG GIT_SHA
ARG BUILD_TAG
ARG BUILD_DATE

# Labels OCI para trazabilidad del build (una clave por linea para auditoria con grep).
LABEL \
org.opencontainers.image.revision=$GIT_SHA \
org.opencontainers.image.created=$BUILD_DATE \
org.opencontainers.image.version=$BUILD_TAG

# Entrypoint real con permisos fijados en COPY (LF garantizado por .gitattributes, sin dos2unix).
COPY --chmod=0755 entrypoint.sh /entrypoint.sh

# Copy the files generated during the build phase to the Nginx directory
COPY --from=build /app/dist/angular_application/browser/. /usr/share/nginx/html

# Crear usuario no-root para el runtime.
RUN addgroup -S appuser && adduser -S appuser -G appuser

# Verificacion de salud: wget (busybox) existe en nginx:alpine, curl no.
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD wget -qO- http://localhost/ || exit 1

# Expose port 80 for web traffic
EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]

# El runtime corre sin privilegios (verificado con docker inspect: User == "appuser").
USER appuser
