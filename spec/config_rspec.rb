# frozen_string_literal: true

# Configure RSpec
RSpec.configure do |config|
  config.include WaitForAjax, type: :feature

  config.fixture_path = Rails.root.join('spec', 'fixtures')
  config.use_transactional_fixtures = false
  config.infer_spec_type_from_file_location!

  # Use DB agnostic schema by default
  load Rails.root.join('db', 'schema.rb').to_s

  # Run tests in random order
  config.order = :random
  Kernel.srand config.seed

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # disable monkey patching
  # see: https://relishapp.com/rspec/rspec-core/v/3-8/docs/configuration/zero-monkey-patching-mode
  config.disable_monkey_patching!

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before do
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end

  if ENV.key?('GITHUB_ACTIONS')
    config.around do |ex|
      ex.run_with_retry retry: 3
    end
  end
end
