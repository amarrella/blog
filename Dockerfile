FROM nginx:1.13.10-alpine
COPY dist /usr/share/nginx/html
EXPOSE 80