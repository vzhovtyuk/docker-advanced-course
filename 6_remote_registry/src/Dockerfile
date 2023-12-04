FROM nginx:1.25.3-alpine
COPY index.html /usr/share/nginx/html/
RUN ARCH=$(uname -a) && \
    sed -i "s|Architecture|$ARCH|g" /usr/share/nginx/html/index.html
EXPOSE 80
