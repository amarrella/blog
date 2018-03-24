FROM nginx:1.13.10-alpine
COPY blog /usr/share/nginx/html
EXPOSE 80