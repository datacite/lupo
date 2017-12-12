# DataCite REST API

[![Build Status](https://travis-ci.org/datacite/lupo.svg?branch=master)](https://travis-ci.org/datacite/lupo) [![Docker Build Status](https://img.shields.io/docker/build/datacite/lupo.svg)](https://hub.docker.com/r/datacite/lupo/)  [![Maintainability](https://api.codeclimate.com/v1/badges/dddd95f9f6f354b7af93/maintainability)](https://codeclimate.com/github/datacite/lupo/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/dddd95f9f6f354b7af93/test_coverage)](https://codeclimate.com/github/datacite/lupo/test_coverage)

Rails API-only application for managing DataCite providers, clients, prefixes and DOIs. The API is based on the [JSONAPI](http://jsonapi.org/) specification.

## Installation

Using Docker.

```
docker run -p 8065:80 datacite/lupo
```

You can now point your browser to `http://localhost:8065` and use the application.

## Development

We use Rspec for unit and acceptance testing:

```
bundle exec rspec
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
