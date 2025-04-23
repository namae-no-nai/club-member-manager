FROM ruby:3.3.5-alpine AS base

RUN apk add --no-cache build-base openssl-dev sqlite-dev tzdata

RUN gem install bundler

WORKDIR /app

COPY . .

VOLUME /app/storage

RUN bundle install

FROM base AS development

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]

FROM base AS production

RUN bundle install --without development test

RUN bundle exec rails assets:precompile

ENV RAILS_ENV=production

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
