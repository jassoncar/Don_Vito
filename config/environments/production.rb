require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false

  # Vercel entrega el contenedor detrás de HTTPS: se asume SSL y se fuerza (excepto el health check).
  config.assume_ssl = true
  config.force_ssl = ENV.fetch("FORCE_SSL", "1") == "1"
  config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  config.public_file_server.enabled = true
  config.public_file_server.headers = { "Cache-Control" => "public, max-age=#{1.day.to_i}" }

  # Los logs van a la salida estándar (el sistema de archivos es de solo lectura).
  logger = ActiveSupport::Logger.new($stdout)
  logger.formatter = ::Logger::Formatter.new
  config.logger = ActiveSupport::TaggedLogging.new(logger)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.log_tags = [:request_id]

  config.cache_store = :memory_store
  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false
  # Defina SECRET_KEY_BASE como variable de entorno.
end
