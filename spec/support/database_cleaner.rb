# frozen_string_literal: true

require "database_cleaner/active_record"

RSpec.configure do |config|
  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, type: :request) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before do
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end
end
