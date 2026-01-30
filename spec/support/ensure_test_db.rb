# frozen_string_literal: true

# Ensure specs never run against development or production DB.
# Only the test database (e.g. habitower_be_test) may be used for adding/removing records.
if defined?(ActiveRecord::Base)
  db_name = ActiveRecord::Base.connection_db_config.configuration_hash[:database].to_s

  if db_name.blank? || db_name.include?("_development") || db_name.include?("_production")
    abort(
      "FATAL: Specs must use the test database only. Current DB: #{db_name.inspect}. " \
      "Set RAILS_ENV=test and ensure DATABASE_URL is unset (or points to *_test)."
    )
  end

  unless db_name.include?("_test")
    abort(
      "FATAL: Test database name must include '_test'. Current: #{db_name.inspect}. " \
      "Check config/database.yml test section."
    )
  end
end
