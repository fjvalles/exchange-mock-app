FROM ruby:3.2-slim

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    libyaml-dev \
    git \
    curl \
    tzdata \
 && rm -rf /var/lib/apt/lists/*

# Pin Bundler version to match Gemfile.lock
RUN gem install bundler -v 2.4.12 --no-document

WORKDIR /app

# Copy only Gemfile — let bundle resolve fresh for linux/amd64
COPY Gemfile ./
RUN bundle install --jobs 4 --retry 3

COPY . .

RUN chmod +x entrypoint.sh

EXPOSE 3000

# Use shell form (not exec form) so environment variables like $PORT are expanded
CMD ["/bin/bash", "entrypoint.sh"]
