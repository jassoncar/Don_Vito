require_relative "boot"
require "rails/all"
Bundler.require(*Rails.groups)
module SistemaComercial
  class Application < Rails::Application
    config.load_defaults 7.2
    config.time_zone = "America/Managua"
    config.i18n.default_locale = :es
    config.generators.system_tests = nil
    config.autoload_lib(ignore: %w[assets tasks])
  end
end
