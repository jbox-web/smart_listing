require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)
require "smart_listing"

module Dummy
  class Application < Rails::Application
    if Rails::VERSION::MAJOR == 7
      config.active_record.legacy_connection_handling = false
    end
  end
end
