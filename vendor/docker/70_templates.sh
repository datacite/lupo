#!/bin/sh
dockerize -template /home/app/webapp/vendor/docker/nginx.conf.tmpl:/etc/nginx/nginx.conf
