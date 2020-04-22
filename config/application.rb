require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Money
  class Application < Rails::Application
    config.web_console.whitelisted_ips = '219.143.154.75'
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2
    config.i18n.default_locale = :cn
    # Settings in config/environments/* take precedence over those specified here.
    config.generators do |g|
      g.test_framework :rspec,
        view_specs:       false,
        controller_specs: false,
        helper_specs:     false,
        routing_specs:    false,
        request_specs:    false
      g.stylesheets       false
      g.javascripts       false
      g.helper            false
      g.jbuilder          false
    end
    # Set Time Zone
    config.time_zone = 'Beijing'
    config.active_record.default_timezone = :local
    config.active_record.time_zone_aware_attributes = false
  end
end
