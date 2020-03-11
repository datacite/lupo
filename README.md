[![Identifier](https://img.shields.io/badge/doi-10.5438%2F8gb0--v673-fca709.svg)](https://doi.org/10.5438/8gb0-v673)
[![Build Status](https://travis-ci.org/datacite/lupo.svg?branch=master)](https://travis-ci.org/datacite/lupo) [![Docker Build Status](https://img.shields.io/docker/build/datacite/lupo.svg)](https://hub.docker.com/r/datacite/lupo/) [![Maintainability](https://api.codeclimate.com/v1/badges/dddd95f9f6f354b7af93/maintainability)](https://codeclimate.com/github/datacite/lupo/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/dddd95f9f6f354b7af93/test_coverage)](https://codeclimate.com/github/datacite/lupo/test_coverage) [![Discourse users](https://img.shields.io/discourse/https/www.pidforum.org/users)](https://www.pidforum.org/c/pid-developers)


# DataCite REST API

Rails API application for managing DataCite providers, clients, prefixes and DOIs. The API is based on the [JSONAPI](http://jsonapi.org/) specification.

## Installation

Using Docker.

```bash
docker run -p 8065:80 datacite/lupo
```

or

```bash
docker-compose up
```

You can now point your browser to `http://localhost:8065` and use the application. Some API endpoints require authentication.

## Development

For basic setup one can use the following:

```bash
bundle exec rake db:create
bundle exec rake db:schema:load
bundle exec rake db:seed:development:base
```

We use Rspec for testing:

```bash
bundle exec rspec
```

Note when using a fresh test database you will need to instantiate the test db with:

```bash
bundle exec rake db:create RAILS_ENV=test
```

Follow along via [Github Issues](https://github.com/datacite/lupo/issues).

### Note on Patches/Pull Requests

* Fork the project
* Write tests for your new feature or a test that reproduces a bug
* Implement your feature or make a bug fix
* Do not mess with Rakefile, version or history
* Commit, push and make a pull request. Bonus points for topical branches.

## License

**Lupo** is released under the [MIT License](https://github.com/datacite/lupo/blob/master/LICENSE).
