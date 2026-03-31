FROM ruby:3.2-slim

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    libyaml-dev \
    git \
    curl \
    tzdata \
 && rm -rf /var/lib/apt/lists/*

# Pin Bundler version
RUN gem install bundler -v 2.4.12 --no-document

WORKDIR /app

# Copy only Gemfile — let bundle resolve fresh for linux/amd64
# (Gemfile.lock was generated on macOS and causes platform conflicts)
COPY Gemfile ./
RUN bundle install --jobs 4 --retry 3

COPY . .

RUN chmod +x entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["./entrypoint.sh"]
