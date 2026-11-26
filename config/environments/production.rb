require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Kamal terminates TLS at its proxy and forwards traffic to the app container.
  config.assume_ssl = true
  config.force_ssl = true

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  config.cache_store = :solid_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }

  app_host = ENV.fetch("APP_HOST")
  config.hosts << app_host
  config.action_mailer.default_url_options = { host: app_host, protocol: "https" }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.smtp_settings = {
    address: ENV.fetch("SMTP_ADDRESS"),
    port: Integer(ENV.fetch("SMTP_PORT", "587"), 10),
    domain: ENV.fetch("SMTP_DOMAIN", app_host),
    user_name: ENV.fetch("SMTP_USERNAME"),
    password: ENV.fetch("SMTP_PASSWORD"),
    authentication: ENV.fetch("SMTP_AUTHENTICATION", "plain").to_sym,
    enable_starttls: true
  }

  checkout_environment = {
    "ADYEN_API_KEY" => ENV.fetch("ADYEN_API_KEY"),
    "ADYEN_HMAC_KEY" => ENV.fetch("ADYEN_HMAC_KEY"),
    "ADYEN_MERCHANT_ACCOUNT" => ENV.fetch("ADYEN_MERCHANT_ACCOUNT"),
    "ADYEN_LIVE_PREFIX" => ENV.fetch("ADYEN_LIVE_PREFIX"),
    "AVATAX_ACCOUNT_ID" => ENV.fetch("AVATAX_ACCOUNT_ID"),
    "AVATAX_LICENSE_KEY" => ENV.fetch("AVATAX_LICENSE_KEY"),
    "AVATAX_COMPANY_CODE" => ENV.fetch("AVATAX_COMPANY_CODE"),
    "MERCHANT_ORIGIN_LINE1" => ENV.fetch("MERCHANT_ORIGIN_LINE1"),
    "MERCHANT_ORIGIN_CITY" => ENV.fetch("MERCHANT_ORIGIN_CITY"),
    "MERCHANT_ORIGIN_REGION" => ENV.fetch("MERCHANT_ORIGIN_REGION"),
    "MERCHANT_ORIGIN_POSTAL_CODE" => ENV.fetch("MERCHANT_ORIGIN_POSTAL_CODE"),
    "MERCHANT_ORIGIN_COUNTRY_CODE" => ENV.fetch("MERCHANT_ORIGIN_COUNTRY_CODE")
  }
  raise "Production checkout requires live Adyen and AvaTax environments" unless
    ENV.fetch("ADYEN_ENVIRONMENT") == "live" && ENV.fetch("AVATAX_ENVIRONMENT") == "production"
  raise "ADYEN_HMAC_KEY must be 64 hexadecimal characters" unless checkout_environment["ADYEN_HMAC_KEY"].match?(/\A[0-9a-f]{64}\z/i)
  raise "ADYEN_LIVE_PREFIX must be a hostname prefix" unless checkout_environment["ADYEN_LIVE_PREFIX"].match?(/\A[a-z0-9-]+\z/i)
  raise "MERCHANT_ORIGIN_COUNTRY_CODE must be an ISO alpha-2 code" unless checkout_environment["MERCHANT_ORIGIN_COUNTRY_CODE"].match?(/\A[A-Z]{2}\z/)

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  #
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
