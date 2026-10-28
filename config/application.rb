require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"

Bundler.require(*Rails.groups)

module Licoreria
  class Application < Rails::Application
    config.load_defaults 7.1

    config.time_zone = "America/Managua"
    config.i18n.default_locale = :es
    config.i18n.available_locales = %i[es en]
    config.i18n.fallbacks = [:en]

    config.generators.system_tests = nil
  end
end
