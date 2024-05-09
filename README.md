# DataCite REST API

[![Identifier](https://img.shields.io/badge/doi-10.5438%2F8gb0--v673-fca709.svg)](https://doi.org/10.5438/8gb0-v673)
![Release](https://github.com/datacite/lupo/workflows/Release/badge.svg)
[![Maintainability](https://api.codeclimate.com/v1/badges/dddd95f9f6f354b7af93/maintainability)](https://codeclimate.com/github/datacite/lupo/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/dddd95f9f6f354b7af93/test_coverage)](https://codeclimate.com/github/datacite/lupo/test_coverage)

Rails API application for managing DataCite providers, clients, prefixes and DOIs. The API usesthe [JSONAPI](http://jsonapi.org/) specification.

## Installation

Using Docker.

```bash
docker run -p 8065:80 datacite/lupo
```

or

```bash
docker-compose up
```

If you want to build the docker image locally (instead of pulling it from docker hub)
 and use docker compose for development you can use
```bash
docker-compose -f docker-compose.yml -f docker-compose.local.yml
```

You can now point your browser to `http://localhost:8065` and use the application. Some API endpoints require authentication.

## Development

For basic setup one can use the following:

```bash
bundle exec rake db:create
bundle exec rake db:schema:load
bundle exec rake db:seed:development:base
```

All other seed options can be found using rake --tasks

We use Rspec for testing:

```bash
bundle exec rspec
```

Note when using a fresh test database you will need to instantiate the test db with:

```bash
bundle exec rake db:create RAILS_ENV=test
```

Note when accessing the console you will need to disable spring:

```bash
env DISABLE_SPRING=true bundle exec rails console
```

Follow along via [Github Issues](https://github.com/datacite/lupo/issues).

### Note on Patches/Pull Requests

- Fork the project
- Write tests for your new feature or a test that reproduces a bug
- Implement your feature or make a bug fix
- Do not mess with Rakefile, version or history
- Commit, push and make a pull request. Bonus points for topical branches.

## License

**Lupo** is released under the [MIT License](https://github.com/datacite/lupo/blob/master/LICENSE).
