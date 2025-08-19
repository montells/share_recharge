## Share Recharge — AI-assisted Rails 8 experiment (Cursor)

This repository is an experiment built end-to-end using AI pair-programming with Cursor. The goal is to demonstrate a practical, production-style Ruby on Rails application created and iterated with AI assistance, suitable to showcase to recruiters and hiring managers.

### What this project highlights
- AI-in-the-loop development: most steps (project bootstrap, tooling, Docker, tests) were executed via Cursor AI.
- Rails way first: idiomatic Rails 8.x, with SOLID and DRY principles in mind.
- Good defaults for performance and maintainability from day one.

### Tech stack
- Ruby 3.3.3, Rails 8.x
- PostgreSQL 16 (via Docker)
- Importmap (no Node by default), Tailwind CSS (tailwindcss-rails)
- Hotwire (Turbo, Stimulus) ready
- Test stack:
  - RSpec (request/model specs), FactoryBot, Faker, DatabaseCleaner
  - Cucumber for end-to-end (Capybara + Selenium)
- Docker Compose for local development

### Quick start (Docker Compose)
Prerequisites: Docker and Docker Compose installed.

1) Start the app:
```bash
docker compose up --build
```

2) Open the app:
```text
http://localhost:3000
```

The `web` service uses a development image (multi-stage `Dockerfile`) and will automatically prepare the database on server start. PostgreSQL is provided by the `db` service.

Useful commands:
- Rails console:
```bash
docker compose run --rm web bin/rails console
```
- Run migrations:
```bash
docker compose run --rm web bin/rails db:migrate
```
- Logs:
```bash
docker compose logs -f
```
- Stop and clean volumes:
```bash
docker compose down -v
```

### Testing
- RSpec:
```bash
docker compose run --rm web bundle exec rspec
```

- Cucumber (E2E):
```bash
docker compose run --rm web bundle exec cucumber
```

The test stack uses FactoryBot syntax methods and DatabaseCleaner to wrap examples. Capybara + Selenium are available for system/E2E scenarios.

### Local development without Docker (optional)
If you prefer a native setup:
- Ruby via RVM: 3.3.3
- PostgreSQL running locally
- Install gems and setup DB:
```bash
bundle install
bin/rails db:prepare
bin/dev
```
App will be available at `http://localhost:3000`.

### Philosophy
- Prefer Rails conventions; keep things simple and maintainable.
- Apply SOLID and DRY principles in code structure and tests.
- Keep feedback loops fast (Dockerized dev, foreman `bin/dev`, and CI-ready layout).

### Notes
- The Dockerfile is multi-stage with a dedicated `dev` target used by `compose.yaml`.
- Production deployment is out of scope for this experiment, but the Dockerfile also contains a production image path compatible with common strategies.

### License
MIT
