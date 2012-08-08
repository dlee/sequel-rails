
require File.expand_path('../rails/core', __FILE__)

module Sequel::Rails
  def self.configuration
    Configuration
  end

  def self.connect(environment)
    @db = Sequel.connect(configuration.db_config_for(environment))
  end

  def self.db
    @db
  end

  def self.connected?
    !!@db
  end

  require libpath('sequel/rails/ext')
  require libpath('sequel/rails/configuration')
  require libpath('sequel/rails/log_subscriber')
  require libpath('sequel/rails/railtie')
end

