
# TODO: DRY these up
# TODO: Add task to create sessions table

######################################################
# BEWARE: Regular Expressions of DOOOOOOOOOOOOOOOOOM #
######################################################
namespace :db do
  namespace :schema do
    desc "Create a db/schema.rb file that can be portably used against any DB supported by Sequel"
    task :dump => :environment do
      Sequel.extension :schema_dumper
      db = Sequel::Rails.db
      File.open(ENV['SCHEMA'] || "#{Rails.root}/db/schema.rb", "w") do |file|
        database = db.dump_schema_migration(same_db: true)
        # 0. Add schema_migrations info (mucho importante!)
        filenames = db[:schema_migrations].map{|x| x[:filename]}
        statements = filenames.map do |f|
          "self[:schema_migrations].insert(:filename => \"#{f}\")"
        end

        inserts = statements.map do |s|
          "    #{s}"
        end.join("\n")

        database.gsub!(/(create_table\(:schema_migrations\) do.+?end)/m, '\1'+"\n\n#{inserts}\n")

        # 1. Fuck arbitrary whitespaces.
        database.gsub!(/\s+$/,"\n")

        # 2. Add new line at end of file
        database += "\n"
        file.write database
      end
      Rake::Task["db:schema:dump"].reenable
    end

    desc "Load a schema.rb file into the database"
    task :load => :environment do
      require 'sequel/rails/storage'
      Sequel::Rails::Storage.new(Rails.env).create

      file = ENV['SCHEMA'] || "#{Rails.root}/db/schema.rb"
      if File.exists?(file)
        require 'sequel/extensions/migration'
        load(file)
        Sequel::Migration.descendants.first.apply(::Sequel::Model.db, :up)
      else
        abort %{#{file} doesn't exist yet. Run "rake db:migrate" to create it then try again. If you do not intend to use a database, you should instead alter #{Rails.root}/config/boot.rb to limit the frameworks that will be loaded}
      end
    end
  end

  namespace :create do
    desc 'Create all the local databases defined in config/database.yml'
    task :all => :environment do
      require 'sequel/rails/storage'
      Sequel::Rails::Storage.create_all
    end
  end

  desc "Create the database defined in config/database.yml for the current Rails.env - also creates the test database if Rails.env.development?"
  task :create, [:env] => :environment do |t, args|
    args.with_defaults(:env => Rails.env)

    require 'sequel/rails/storage'
    Sequel::Rails::Storage.new(args.env).create

    if Rails.env.development? && Rails.configuration.database_configuration['test']
      Sequel::Rails::Storage.new('test').create
    end
  end

  namespace :drop do
    desc 'Drops all the local databases defined in config/database.yml'
    task :all => :environment do
      require 'sequel/rails/storage'
      Sequel::Rails::Storage.drop_all
    end
  end

  desc "Create the database defined in config/database.yml for the current Rails.env - also creates the test database if Rails.env.development?"
  task :drop, [:env] => :environment do |t, args|
    args.with_defaults(:env => Rails.env)

    require 'sequel/rails/storage'
    Sequel::Rails::Storage.new(args.env).drop

    if Rails.env.development? && Rails.configuration.database_configuration['test']
      Sequel::Rails::Storage.new('test').drop
    end
  end

  namespace :migrate do
    task :load => :environment do
      require 'sequel/rails/migrations'
    end

    desc  'Rollbacks the database one migration and re migrate up. If you want to rollback more than one step, define STEP=x. Target specific version with VERSION=x.'
    task :redo => :load do
      if ENV["VERSION"]
        Rake::Task["db:migrate:down"].invoke
        Rake::Task["db:migrate:up"].invoke
      else
        Rake::Task["db:rollback"].invoke
        Rake::Task["db:migrate"].invoke
      end
    end


    desc 'Resets your database using your migrations for the current environment'
    task :reset => ["db:drop", "db:create", "db:migrate"]

    desc 'Runs the "up" for a given migration VERSION.'
    task :up => :load do
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version
      Sequel::Rails::Migrations.migrate_up!(version)
      Rake::Task["db:schema:dump"].invoke if Rails.env != 'test'
    end

    desc 'Runs the "down" for a given migration VERSION.'
    task :down => :load do
      version = ENV["VERSION"] ? ENV["VERSION"].to_i : nil
      raise "VERSION is required" unless version
      Sequel::Rails::Migrations.migrate_down!(version)
      Rake::Task["db:schema:dump"].invoke if Rails.env != 'test'
    end
  end

  desc 'Migrate the database to the latest version'
  task :migrate => :'migrate:load' do
    Sequel::Rails::Migrations.migrate_up!(ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
    Rake::Task["db:schema:dump"].invoke if Rails.env != 'test'
  end

  desc 'Rolls the schema back to the previous version. Specify the number of steps with STEP=n'
  task :rollback => :'migrate:load' do
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    Sequel::Migrator.rollback('db/migrate/', step)
    Rake::Task["db:schema:dump"].invoke if Rails.env != 'test'
  end

  desc 'Pushes the schema to the next version. Specify the number of steps with STEP=n'
  task :forward => :'migrate:load' do
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    Sequel::Migrator.forward('db/migrate/', step)
    Rake::Task["db:schema:dump"].invoke if Rails.env != 'test'
  end

  desc 'Load the seed data from db/seeds.rb'
  task :seed => :environment do
    seed_file = File.join(Rails.root, 'db', 'seeds.rb')
    load(seed_file) if File.exist?(seed_file)
  end

  desc 'Create the database, load the schema, and initialize with the seed data'
  task :setup => [ 'db:create', 'db:schema:load', 'db:seed' ]
  
  desc 'Drops and recreates the database from db/schema.rb for the current environment and loads the seeds.'
  task :reset => [ 'db:drop', 'db:setup' ]

  desc 'Forcibly close any open connections to the test database'
  task :force_close_open_connections => :environment do
    if Rails.env.test?
       db_config = Rails.configuration.database_configuration[Rails.env].symbolize_keys
       begin
         #Will only work on Postgres > 8.4
         Sequel::Model.db.execute <<-SQL.gsub(/^\s{9}/,'')
         SELECT COUNT(pg_terminate_backend(procpid))
         FROM  pg_stat_activity
         WHERE datname = '#{db_config[:database]}';
         SQL
       rescue => e
         #Will raise an error as it kills existing process running this command
         #Seems to be only way to ensure *all* test connections are closed
       end
     end
  end

  namespace :test do
    task :prepare do
      Rails.env = 'test'
      Rake::Task['db:force_close_open_connections'].invoke()
      Rake::Task['db:drop'].invoke()
      Rake::Task['db:create'].invoke()
      Rake::Task['db:schema:load'].invoke()
      Sequel::DATABASES.each do |db|
        db.disconnect
      end
    end
  end
end

task 'test:prepare' => 'db:test:prepare'

