Devise.setup do |config|
  config.mailer_sender = "admin@example.com"
  require "devise/orm/active_record"
  config.parent_mailer = "ActionMailer::Base"
  config.secret_key = ENV.fetch("DEVISE_SECRET_KEY", ENV.fetch("SECRET_KEY_BASE", "development-only-change-this-secret"))
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? 1 : 12
  config.reconfirmable = true
  config.expire_all_remember_me_on_sign_out = true
  config.password_length = 8..128
  config.sign_out_via = :delete
end
