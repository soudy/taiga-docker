# Taiga Docker container
This repository holds an image ready-to-use setup for Taiga using Docker
compose. You can launch an instance by simply running `docker-compose up`.

## Configuration
Application configuration can be done in `taiga-conf/local.py` and
`taiga-conf/conf.json`. The most important thing is setting your hostname both
in `docker-compose.yml` and `taiga-conf/conf.json`, otherwise the front-end
won't be able to talk with the back-end.
