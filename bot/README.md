Python slackbot
===============

> Slackbot skrevet i Python, som hjelper deg å ha en virtuel stand-up

Kommuniser med bot'en med tre enkle kommandoer: `idag`, `igår`, `problem`.


## Utvikling

Bot'en er utviklet i Python3.7. Anbefaler å bruke `virtualenv` for utvikling.


## Deployment

Vi kjører på Google App Engine, deployes med:
```bash
gcloud app deploy slackbot.yaml -q
```


### Eksempel på config

```yaml
runtime: python37
instance_class: B1
service: slackbot
entrypoint: python bot.py
env_variables:
  SLACK_BOT_TOKEN: <some-value>
  POSTGRES_USER: <some-value
  POSTGRES_PASSWORD: <some-value>
  POSTGRES_SOCKET_PATH: <some-value>
beta_settings:
  cloud_sql_instances: <database-url>
handlers:
 - url: '/.*'
   script: auto
manual_scaling:
  instances: 1
```
