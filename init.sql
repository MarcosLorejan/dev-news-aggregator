-- Create test database.
-- The Postgres entrypoint runs this as POSTGRES_USER (see docker-compose.yml),
-- so that role owns the database and needs no extra grant. Keeping the owner
-- implicit means changing POSTGRES_USER in .env does not break this script.
CREATE DATABASE dev_news_aggregator_test;
