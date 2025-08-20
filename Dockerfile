# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t share_recharge .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name share_recharge share_recharge

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.3.3
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    chromium \
    curl \
    ffmpeg \
    ffmpegthumbnailer \
    gettext-base \
    git-core \
    jpegoptim \
    libjemalloc2 \
    libpq-dev \
    libssl-dev \
    libvips \
    libxml2-dev \
    watchman \
    moreutils \
    postgresql-client \
    unzip && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives /tmp/* && \
    truncate -s 0 /var/log/*log

# Base runtime bundler path
ENV BUNDLE_PATH="/usr/local/bundle"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    git \
    make \
    gcc \
    libssl-dev \
    pkg-config \
    zlib1g-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives /tmp/* && \
    truncate -s 0 /var/log/*log

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle update net-pop && \
    bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile




# Final stage for app image
FROM base

# Set production environment in the final image only
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_WITHOUT="development"

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start server via Thruster by default, this can be overwritten at runtime
EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]

# Development stage
FROM base AS dev

# Install packages needed to build gems (development)
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    libpq-dev \
    make \
    gcc \
    libssl-dev \
    libxml2-dev \
    libyaml-dev \
    pkg-config \
    watchman \
    zlib1g-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives /tmp/* && \
    truncate -s 0 /var/log/*log

# Install application gems with fix for net-pop dependency issue
COPY Gemfile Gemfile.lock ./
RUN bundle update net-pop && \
    bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Copy application code
COPY . .

# Development environment
ENV RAILS_ENV="development"

# Expose dev port
EXPOSE 3000

# Entrypoint prepares db when running server
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Default dev command
# CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
CMD ["./bin/thrust", "./bin/rails", "server"]