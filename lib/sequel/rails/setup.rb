require 'active_support/core_ext/hash/except'

require 'sequel/extensions/migration'

require 'sequel/rails/configuration'
require 'sequel/rails/runtime'
require 'sequel/rails/railties/benchmarking_mixin'

module Sequel
  module Rails

    def self.setup(environment)
      ::Sequel.connect({:logger => configuration.logger}.merge(::Sequel::Rails.configuration.environment_for(environment.to_s)))
    end

  end
end
