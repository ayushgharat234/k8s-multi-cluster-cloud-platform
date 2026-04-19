FROM nginx:1.27-alpine
RUN apk add --no-cache gettext && \
    mkdir -p /tmp/nginx/client_body /tmp/nginx/proxy /tmp/nginx/fastcgi && \
    chown -R nginx:nginx /tmp/nginx /var/cache/nginx && \
    chmod -R 755 /tmp/nginx
COPY nginx.conf /etc/nginx/templates/default.conf.template
COPY src/index.html /usr/share/nginx/html/index.html
EXPOSE 80
USER nginx
HEALTHCHECK --interval=15s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:80/health || exit 1
CMD ["/bin/sh", "-c", "envsubst '${CATALOG_URL}' < /etc/nginx/templates/default.conf.template > /tmp/nginx/nginx.conf && nginx -c /tmp/nginx/nginx.conf -g 'daemon off;'"]
