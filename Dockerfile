# docker build -t club-member:prod .
# docker run -p 3000:3000 --env-file .env -v club-member-data:/rails/storage --name club-member club-member:prod
# Don't forget to create/fill out the .env file - `cp .example.env .env` in case you don't have one yet

FROM ruby:3.3.5-alpine AS base

RUN apk add --no-cache build-base openssl-dev sqlite-dev tzdata

RUN gem install bundler

WORKDIR /rails

COPY . .

VOLUME /rails/storage

RUN bundle install

FROM base AS development

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]

FROM base AS production

RUN bundle install --without development

RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

ENV RAILS_ENV=production_local

RUN chmod +x /rails/bin/entrypoint
ENTRYPOINT ["/rails/bin/entrypoint"]

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
