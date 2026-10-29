FROM ruby:3.3-slim
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    build-essential default-libmysqlclient-dev git curl pkg-config \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY Gemfile ./
RUN bundle config set without 'development:test' && bundle install || bundle install
COPY . .
RUN chmod +x bin/docker-entrypoint
EXPOSE 3000
ENTRYPOINT ["./bin/docker-entrypoint"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
