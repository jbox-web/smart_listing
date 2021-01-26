RSpec.configure do |config|
  config.include WaitForAjax, type: :feature

  config.fixture_path = "#{::Rails.root}/fixtures"
  config.use_transactional_fixtures = false
  config.infer_spec_type_from_file_location!

  # Run tests in random order
  config.order = :random
  Kernel.srand config.seed

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # disable monkey patching
  # see: https://relishapp.com/rspec/rspec-core/v/3-8/docs/configuration/zero-monkey-patching-mode
  config.disable_monkey_patching!

  DatabaseCleaner.strategy = :truncation

  config.before :each do
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end
end
