# frozen_string_literal: true

# Development-only: load allowlisted keys from `.env` into ENV when unset.
# Production uses Kamal secrets; tests set ENV explicitly.
require Rails.root.join("lib/local_env")

LocalEnv.load! if Rails.env.development?
