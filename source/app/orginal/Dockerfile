FROM alpine:3.9 as app-builder
MAINTAINER CyberArk
LABEL builder="app-builder"

#---some useful tools for interactive usage---#
RUN apk update && \
    apk upgrade && \
    apk add bash curl && \
    rm -rf /var/cache/apk/*

# ============= MAIN CONTAINER ============== #
FROM alpine:3.9
MAINTAINER CyberArk

ENV BUILD_PACKAGES bash curl build-base vim
ENV DB_PACKAGES mariadb-dev
ENV RUBY_PACKAGES ruby-full ruby-io-console ruby-bundler ruby-rdoc ruby-dev

# Update and install all of the required packages.
# At the end, remove the apk cache
RUN apk update && \
    apk upgrade && \
    apk add $BUILD_PACKAGES && \
    apk add $DB_PACKAGES && \
    apk add $RUBY_PACKAGES && \
    rm -rf /var/cache/apk/*

WORKDIR /usr/src

RUN gem install -N activesupport --version 4.2.11.1
RUN gem install -N sinatra
RUN gem install mysql2 --platform=ruby

COPY cityapp.rb  /usr/src/

ENV PORT 3000
EXPOSE 3000

CMD [ "ruby", "/usr/src/cityapp.rb", "-o", "0.0.0.0" ]
#CMD [ "sleep", "infinity" ]
