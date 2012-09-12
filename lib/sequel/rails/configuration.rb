
require 'active_support/core_ext/hash/keys'

module Sequel
  module Rails
    module Configuration
      class << self
        attr_accessor :logger, :db_environments

        def truncate_sql_to=(len)
          @sql_truncate_length = len
        end
        attr_reader :sql_truncate_length

        def init_database(db_config)
          @db_config = db_config
          @db_environments = db_config.inject({}) { |hash, (name, config)|
            hash[name.to_sym] = normalize_repository_config(config)
            hash
          }
        end

        def db_config_for(name)
          @db_environments[name.to_sym].merge(:logger => logger)
        end

      private
        def normalize_repository_config(hash)
          hash = hash.stringify_keys

          port = hash.delete('port')
          adapter = hash.delete('adapter')
          database = hash.delete('database')

          config = {}
          config['port'] = port.try(:to_i)
          config['adapter'] = case adapter
            when 'sqlite3'    then 'sqlite'
            when 'postgresql' then 'postgres'
            else                   adapter
          end
          config['database'] =
            if adapter =~ /^sqlite3?/ and database != ':memory:'
              File.expand_path(database, ::Rails.root)
            else
              database
            end

          config.merge!(hash)
          config
        end
      end
    end
  end
end

