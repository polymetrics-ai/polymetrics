# Use an official Ruby runtime as a parent image
FROM ruby:3.2.0-slim

# Set the working directory in the container
WORKDIR /ruby_connectors


# Update and install dependencies
RUN apt-get update && \
  apt-get install -y \
  build-essential \
  libpq-dev \
  libvips \
  pkg-config \
  git

# Copy the Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ruby_connectors.gemspec ./

# Install bundler and gems
RUN bundle install

# Copy the rest of the application code
COPY . .

# Set the entrypoint to run the temporal_worker
ENTRYPOINT ["bin/temporal_worker"]