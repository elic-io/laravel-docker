FROM nginx

RUN apt-get update && apt-get install -y vim \
    sendmail

COPY ./nginx/vhost.conf /etc/nginx/conf.d/default.conf

COPY public /var/www/public

