# syntax=docker/dockerfile:1
# Build the static site once on the build machine's architecture, then serve it with unprivileged nginx
# (runs as a non-root user on port 8080, so it passes Pod Security "restricted").
FROM --platform=$BUILDPLATFORM node:20-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginxinc/nginx-unprivileged:1.27-alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY ./nginx/nginx.conf /etc/nginx/nginx.conf
EXPOSE 8080
