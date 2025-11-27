# DataCite REST API

[![Identifier](https://img.shields.io/badge/doi-10.5438%2F8gb0--v673-fca709.svg)](https://doi.org/10.5438/8gb0-v673)
![Release](https://github.com/datacite/lupo/workflows/Release/badge.svg)
[![Maintainability](https://api.codeclimate.com/v1/badges/dddd95f9f6f354b7af93/maintainability)](https://codeclimate.com/github/datacite/lupo/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/dddd95f9f6f354b7af93/test_coverage)](https://codeclimate.com/github/datacite/lupo/test_coverage)

Rails API application for managing DataCite providers, clients, prefixes and DOIs. The API usesthe [JSONAPI](http://jsonapi.org/) specification.

## Development

We use Docker Compose for development to ensure a consistent environment.

### Configuration

You do not need a complicated `.env` file to get started. Reasonable defaults are set for both development and test environments and are loaded automatically by Rails. You can start with an empty `.env` file or override specific values as needed.

### Starting the Application

To build and start the application and its dependencies:

```bash
docker-compose -f docker-compose.yml -f docker-compose.local.yml up --build
```

### Database Setup

Once the containers are running, you can set up the database (create, schema load, seed):

```bash
docker-compose exec web bundle exec rake db:setup RAILS_ENV=development
```
### Accessing the Application

The application will be available at `http://localhost:8065`.

Useful endpoints to visit include:
*   `http://localhost:8065/dois`
*   `http://localhost:8065/clients`


### Running Tests

To run the entire test suite:

```bash
docker-compose exec web bundle exec rspec
```

To run a specific test file:

```bash
docker-compose exec web bundle exec rspec spec/models/doi_spec.rb
```

To run a specific test at a specific line:

```bash
docker-compose exec web bundle exec rspec spec/models/doi_spec.rb:10
```

### Rails Console

To access the Rails console:

```bash
docker-compose exec web env DISABLE_SPRING=true bundle exec rails console
```

Alternatively, you can open a shell inside the container to run commands:

```bash
docker-compose exec web bash
```

Follow along via [Github Issues](https://github.com/datacite/lupo/issues).

### Note on Patches/Pull Requests

- Fork the project.
- Write tests for your new feature or a test that reproduces a bug.
- Implement your feature or make a bug fix.
- Do not mess with Rakefile, version or history.
- Commit, push and make a pull request. Bonus points for topical branches.

## License

**Lupo** is released under the [MIT License](https://github.com/datacite/lupo/blob/master/LICENSE).
