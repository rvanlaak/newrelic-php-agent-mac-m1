FROM php:8.1-fpm-alpine as app

# Environment arguments as retrieved from the docker-compose build args
ARG APP_NAME=${APP_NAME:-''}
ARG NEW_RELIC_ENABLED=${NEW_RELIC_ENABLED:-0}
ARG NRIA_LICENSE_KEY=${NRIA_LICENSE_KEY:-0}

# New Relic Install, and automated version of the instructions at https://docs.newrelic.com/docs/agents/php-agent/installation/php-agent-installation-tar-file
# configures some of the .ini values to use environment variables
RUN cd ~ \
    && export NEWRELIC_VERSION="$(curl -sS https://download.newrelic.com/php_agent/release/ | sed -n 's/.*>\(.*linux-musl\).tar.gz<.*/\1/p')" \
    && curl -sS "https://download.newrelic.com/php_agent/release/${NEWRELIC_VERSION}.tar.gz" | gzip -dc | tar xf - \
    && cd "${NEWRELIC_VERSION}" \
    && NR_INSTALL_USE_CP_NOT_LN=true NR_INSTALL_SILENT=true ./newrelic-install install \
    && cd .. \
    && unset NEWRELIC_VERSION \
    && sed -i \
        -e "s/;\?newrelic.enabled =.*/newrelic.enabled = ${NEW_RELIC_ENABLED}/" \
        -e "s/newrelic.license =.*/newrelic.license = ${NRIA_LICENSE_KEY}/" \
        -e "s/newrelic.appname =.*/newrelic.appname = ${APP_NAME}/" \
#        -e "s/newrelic.daemon.logfile =.*/newrelic.daemon.logfile = \/app\/var\/log\/newrelic-daemon\.log/" \
#        -e "s/;\?newrelic.daemon.address =.*/newrelic.daemon.address = \/app\/var\/cache\/\.newrelic\.sock/" \
        -e 's/;newrelic.daemon.app_connect_timeout =.*/newrelic.daemon.app_connect_timeout=15s/' \
        -e 's/;newrelic.daemon.start_timeout =.*/newrelic.daemon.start_timeout=5s/' \
        /usr/local/etc/php/conf.d/newrelic.ini
