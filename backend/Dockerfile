FROM ruby:3.2-slim

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    git \
    curl \
    tzdata \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Pin Bundler to same version as Gemfile.lock to avoid resolution errors
RUN gem install bundler -v 2.4.12 --no-document

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

COPY . .

RUN chmod +x entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["./entrypoint.sh"]
