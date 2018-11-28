FROM ruby:2.5.3

ADD . /geocoder
WORKDIR /geocoder
RUN bundle install

ENV PORT 8080
EXPOSE $PORT

ENTRYPOINT ["bundle", "exec", "ruby", "app.rb"]