FROM node:22.18-alpine AS build

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

FROM nginx:alpine

# Copy the files generated during the build phase to the Nginx directory
COPY --from=build /app/dist/angular_application/browser/. /usr/share/nginx/html

# Copy the entry script
COPY entrypoint.sh /entrypoint.sh

# Make the script executable
RUN chmod 755 /entrypoint.sh && dos2unix /entrypoint.sh

# Expose port 80 for web traffic
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
