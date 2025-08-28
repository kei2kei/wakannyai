# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.3.0
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim as base

# Rails app lives here
WORKDIR /my_blog_app

# Set production environment
ENV RAILS_ENV="development" \
  BUNDLE_DEPLOYMENT="1" \
  BUNDLE_PATH="/usr/local/bundle" \
  BUNDLE_WITHOUT="development"


# Throw-away build stage to reduce size of final image
FROM base as build

RUN apt-get update -qq && \
  apt-get install --no-install-recommends -y build-essential git libpq-dev libvips pkg-config curl && \
# NodeSourceからNode.jsのレポジトリ情報を取得・インストール
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
# Yarnの公式公開鍵とレポジトリを追加
  curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
  apt-get update -qq && \
# nodejsとyarnをインストール
  apt-get install -y nodejs && \
  npm install -g yarn && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
  rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
  bundle exec bootsnap precompile --gemfile

# JavaScript依存関係のインストール
COPY package.json yarn.lock ./
RUN yarn install

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile


# Final stage for app image
FROM base

# Install packages needed for deployment
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential curl libvips postgresql-client && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /my_blog_app /my_blog_app

# Run and own only the runtime files as a non-root user for security
RUN useradd -m -s /bin/bash rails && \
  chown -R rails:rails /my_blog_app
USER rails

# Entrypoint prepares the database.
ENTRYPOINT ["/my_blog_app/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["./bin/rails", "server"]
