require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ClubMemberManager
  class Application < Rails::Application
    config.load_defaults 8.0

    config.i18n.available_locales = :'pt-BR'
    config.i18n.available_locales = [ :en, :'pt-BR' ]

    config.i18n.default_locale = :'pt-BR'
    config.i18n.fallbacks = true

    config.time_zone = 'Brasilia'
    config.active_record.default_timezone = :local
    config.autoload_lib(ignore: %w[assets tasks])
  end
end
