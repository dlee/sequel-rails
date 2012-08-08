
# Prevent this file from being loaded twice
unless defined?(SEQUEL_RAILS)

SEQUEL_RAILS = 1

require 'sequel'

module Sequel
  module Rails

    PATH = ::File.expand_path('../../../..', __FILE__)
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

  end
end

end
