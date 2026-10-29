FROM ruby:3.3-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential default-libmysqlclient-dev default-mysql-client git \
    && rm -rf /var/lib/apt/lists/*

ENV BUNDLE_PATH=/usr/local/bundle \
    RAILS_ENV=development

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh && chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /app
EXPOSE 3000
ENTRYPOINT ["entrypoint.sh"]
