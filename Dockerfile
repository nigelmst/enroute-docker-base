FROM php:7.1-fpm-alpine

RUN echo "http://dl-cdn.alpinelinux.org/alpine/v3.10/main" >> /etc/apk/repositories
ARG CHROMIUM_DEPENDENCIES="nss freetype harfbuzz ca-certificates"
RUN apk add --update --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/v3.10/main chromium $CHROMIUM_DEPENDENCIES

# Install system dependencies
RUN echo "http://dl-cdn.alpinelinux.org/alpine/latest-stable/main" >> /etc/apk/repositories
ARG APK_COMMON_DEPENDENCIES="bash dcron busybox-suid libcap curl zip unzip git nodejs npm ca-certificates ttf-freefont"
ARG FONTS="fontconfig ttf-dejavu ttf-droid ttf-liberation ttf-ubuntu-font-family"
RUN apk add --update --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/latest-stable/main $APK_COMMON_DEPENDENCIES $FONTS

# Install PHP extensions
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/bin/
ARG PHP_EXTENSIONS="intl bcmath gd pdo_mysql opcache redis uuid exif pcntl zip imagick exif soap sockets"
RUN install-php-extensions $PHP_EXTENSIONS

# Install supervisord
COPY --from=ochinchina/supervisord:latest /usr/local/bin/supervisord /usr/local/bin/supervisord

# Install caddy
COPY --from=caddy:2.4.3 /usr/bin/caddy /usr/local/bin/caddy
RUN setcap 'cap_net_bind_service=+ep' /usr/local/bin/caddy

# Install composer 2
COPY --from=composer/composer:2.0.14 /usr/bin/composer /usr/local/bin/composer

# Install wkhtml
COPY --from=ghcr.io/surnet/alpine-wkhtmltopdf:3.10-0.12.6-full /bin/wkhtmltopdf /usr/local/bin/wkhtmltopdf
COPY --from=ghcr.io/surnet/alpine-wkhtmltopdf:3.10-0.12.6-full /bin/wkhtmltoimage /usr/local/bin/wkhtmltoimage

# Add & switch to non-root user: 'app'
ENV NON_ROOT_GROUP=${NON_ROOT_GROUP:-app}
ENV NON_ROOT_USER=${NON_ROOT_USER:-app}
RUN addgroup -S $NON_ROOT_GROUP && adduser -S $NON_ROOT_USER -G $NON_ROOT_GROUP
RUN addgroup $NON_ROOT_USER wheel

# Install global node dependencies
ENV NPM_CONFIG_PREFIX=~/.npm-global
ENV PATH "$PATH:/home/$NON_ROOT_USER/.npm-global/bin"
USER $NON_ROOT_USER
RUN npm install -g pm2
