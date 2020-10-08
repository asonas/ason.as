from ruby:3.0.0-preview1

COPY Gemfile /tmp/Gemfile
COPY Gemfile.lock /tmp/Gemfile.lock
RUN cd /tmp && bundle install -j4

WORKDIR /app
COPY . /app
RUN cp -a /tmp/.bundle /tmp/vendor /app/

CMD ["bundle", "exec", "rackup", "config.ru", "-p", "4567"]
