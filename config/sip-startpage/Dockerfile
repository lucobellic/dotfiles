FROM alpine:latest AS builder

RUN apk add --no-cache git

RUN git clone --depth 1 https://github.com/bgibson72/Sip-StartPage.git /app

# Inject init-config.js script into index.html
RUN sed -i 's|<head>|<head><script src="init-config.js"></script>|' /app/index.html

# Remove developer-credits div
RUN sed -i '/<div class="developer-credits">/,/<\/div>/d' /app/index.html

FROM nginx:alpine

COPY --from=builder /app /usr/share/nginx/html

EXPOSE 80
