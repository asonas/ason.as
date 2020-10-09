FROM ruby:3.0.0-preview1

WORKDIR /app
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN bundle install -j4

COPY . /app

CMD ["bundle", "exec", "rackup", "config.ru", "-p", "4567"]
