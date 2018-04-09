Standbot
========
> A simple and useful stand-up bot

## Features

* Contacts all team members each workday at 10 and ask for a report
* Check you report, or the report for all members, either in chat or online


# Development locally

Run a Docker container with postgres:
```bash
docker run --name postgres -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=standbot -p 5432:5432 -d postgres:latest
```

If you already have a container running, you can add a new database with the following command:
```bash
docker exec -it postgres psql -U postgres -c "CREATE DATABASE standbot"
```

Then install `Ruby-2.3.6` and install Gem's with `bundle install'.

Start the app with `foreman start`. It will look for `SLACK_API_TOKEN` in your `.env`-file.
