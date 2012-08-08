
# This is basically adapted straight from ActiveRecord

require 'rails/generators/named_base'
require 'rails/generators/migration'

module Sequel::Generators
  class Base < ::Rails::Generators::NamedBase
    include ::Rails::Generators::Migration

    # Implement the required interface for Rails::Generators::Migration.
    #
    def self.next_migration_number(dirname) #:nodoc:
      next_migration_number = current_migration_number(dirname) + 1
      [Time.now.utc.strftime("%Y%m%d%H%M%S"), "%.14d" % next_migration_number].max
    end

  protected
    # Sequel does not care if migrations have the same name as long as
    # they have different ids.
    #
    def migration_exists?(dirname, file_name) #:nodoc:
      false
    end
  end
end
