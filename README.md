# Datacentre API for DataCite

[![Identifier](https://img.shields.io/badge/doi-10.5438%2Ft1jg--hvhn-fca709.svg)](https://doi.org/10.5438/t1jg-hvhn)
[![Build Status](https://travis-ci.org/datacite/lupo.svg?branch=no-solr)](https://travis-ci.org/datacite/lupo) [![Code Climate](https://codeclimate.com/github/datacite/lupo/badges/gpa.svg)](https://codeclimate.com/github/datacite/lupo) [![Test Coverage](https://codeclimate.com/github/datacite/lupo/badges/coverage.svg)](https://codeclimate.com/github/datacite/lupo/coverage)

Rails API only application for managing the Members, Datacentres and Prefixes from the DataCite database. The API is based on the JSONAPI specification.

## Installation

Using Docker.

```
docker run -p 8065:80 datacite/lupo
```

You can now point your browser to `http://localhost:8065` and use the application.

## Development

We use Rspec for unit and acceptance testing:

```
bundle exec rspec spec
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
