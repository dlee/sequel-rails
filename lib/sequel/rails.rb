
require 'sequel'

# Prevent this file from being loaded twice
unless defined?(SEQUEL_RAILS)

SEQUEL_RAILS = 1

module Sequel
  module Rails
    PATH = ::File.expand_path('../../..', __FILE__)
    LIBPATH = ::File.join(PATH, 'lib')

    # Get the root path of the project. If any arguments are given, they are
    # concatenated to the path using `File.join`.
    #
    def self.path(*args)
      rv = ::File.join(PATH, args.flatten)
      if block_given?
        begin
          $LOAD_PATH.unshift(PATH)
          rv = yield
        ensure
          $LOAD_PATH.shift
        end
      end
      return rv
    end

    # Get the library path of the project. If any arguments are given, they are
    # concatenated to the path using `File.join`.
    #
    def self.libpath(*args)
      rv = ::File.join(LIBPATH, args.flatten)
      if block_given?
        begin
          $LOAD_PATH.unshift(LIBPATH)
          rv = yield
        ensure
          $LOAD_PATH.shift
        end
      end
      return rv
    end

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
end

end

