FROM ruby:3.0.1-alpine

RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    tzdata \
    git \
    curl

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

COPY . .

RUN chmod +x entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["./entrypoint.sh"]
