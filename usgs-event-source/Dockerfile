FROM ruby:2.5.3-alpine3.8

ADD . /usgs-event-source
WORKDIR /usgs-event-source
RUN bundle install

ENTRYPOINT ["bundle", "exec", "ruby", "usgs-event-source.rb"]