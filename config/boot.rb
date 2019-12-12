ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

RAILS_ROOT = File.expand_path('../', __dir__) unless defined?(RAILS_ROOT)

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
