
require File.expand_path('../../rails', __FILE__)

if not defined?(Rails)
  raise "Rails must be loaded before Sequel::Rails::Railtie is loaded"
end
if Rails.version.to_i < 3
  raise "sequel-rails requires Rails >= 3"
end

module Sequel
  module Rails
    require libpath('sequel/rails/railties/i18n_support')
    require libpath('sequel/rails/railties/controller_runtime')

    class Railtie < ::Rails::Railtie
      config.sequel = Sequel::Rails.configuration

      Sequel::Rails::LogSubscriber.attach_to :sequel

      config.app_generators.orm :sequel, :migration => true

      config.action_dispatch.rescue_responses.merge!(
        # If a record cannot be found within an action (resulting from a call
        # to #find!, which is a method we patch into Sequel::Model), then rescue
        # it as a 404
        'Sequel::Plugins::RailsExtensions::ModelNotFound' => :not_found,
        # If a record fails validation within an action, rescue it as a 500
        'Sequel::ValidationFailed'                        => :unprocessable_entity,
        # If something bad happens, rescue it as a 500
        'Sequel::NoExistingObject'                        => :unprocessable_entity
      )

      rake_tasks do
        load Sequel::Rails.libpath('sequel/rails/railties/database.rake')
      end

      initializer 'sequel.logger' do |app|
        app.config.sequel.logger ||=
          if defined?(Logging)
            Logging.logger['Sequel']
          else
            ::Rails.logger
          end
      end

      initializer 'sequel.i18n_support' do |app|
        Sequel::Model.class_eval { include Sequel::Rails::Railties::I18nSupport }
      end

      # Expose database runtime to controller for logging.
      initializer 'sequel.log_runtime' do |app|
        ActiveSupport.on_load(:action_controller) do
          include Sequel::Rails::Railties::ControllerRuntime
        end
      end

      initializer 'sequel.connect' do |app|
        Sequel::Rails.configuration.init_database(app.config.database_configuration)
        Sequel::Rails.connect(::Rails.env)
      end

      # Run setup code after_initialize to make sure all config/initializers
      # are in effect once we setup the connection. This is especially necessary
      # for the cascaded adapter wrappers that need to be declared before setup.
      config.after_initialize do |app|
        Sequel::Model.raise_on_save_failure = false
        Sequel::Model.plugin :active_model
        Sequel::Model.plugin :validation_helpers
        # This is our own plugin
        Sequel::Model.plugin :rails_extensions
      end
    end

  end
end
