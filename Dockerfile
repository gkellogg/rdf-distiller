FROM ruby:2.1.5

WORKDIR /var/www/
RUN gem install foreman

ADD . /var/www/

RUN bundle install

ENV PORT 80
EXPOSE 80

CMD ["foreman", "start"]
