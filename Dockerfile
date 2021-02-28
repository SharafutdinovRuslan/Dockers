FROM ubuntu:14.04

LABEL maintainer='Sharafutdinov Ruslan'


ENTRYPOINT ping www.google.com # shell format not recomended
#ENTRYPOINT ["ping", "www.google.com"]
