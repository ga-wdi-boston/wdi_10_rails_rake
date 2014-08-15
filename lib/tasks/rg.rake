require 'active_record'
require 'active_record/fixtures'

# task :bar do
#   puts "IN bar task"
# end
# desc ' Testing foo[param1, param2] '
# task :foo, :param1, :param2, :needs =>[:bar] do |t, args|
# #  Rake::Task[:environment].execute
#   puts "TGD: Rails.env #{Rails.env.inspect}"

#   puts "args[:param1] = #{args[:param1]}"
#   puts "args[:param2] = #{args[:param2]}"
# end

namespace :db do

  desc "copy[from,to] - Copy data 'from' DB 'to' another DB, default from DB = 'client_backup' default to DB = 'development"
  task :copy, :from, :to, :needs => [:environment] do |t, args|

    # DB to get data from, client_backup MUST be in the database.yml
    from = args[:from] || 'client_backup'

    # DB to copy data to
    to = args[:to] || RAILS_ENV || 'development'

    puts "copying data from DB \"#{from}\" ===> DB \"#{to}\" "

    puts "copying data from DB #{from} "

    # Lets get the data
    ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations[from])
    backup_conn = ActiveRecord::Base.connection

    sql = "SELECT * FROM %s"

    skip_tables = ["schema_info" ]
    tables = ActiveRecord::Base.connection.tables - skip_tables
    # tables = ['users']
    backup_data = []
    tables.each do |table_name|
      table = { }
      table[table_name] = backup_conn.select_all(sql % table_name)
      backup_data << table
    end
    puts "Done, copying data from DB #{from} "
    puts "initialize the DB, #{to}, being copyied into"

    RAILS_ENV = to
    Rake::Task["db:drop"].invoke
    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke

    # Copy to
    ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations[to])
    dev_conn = ActiveRecord::Base.connection

    backup_data.each do |table_data|
      table_data.each_pair do |table_name, records|
        puts "Insert into DB \"#{to}\" table \"#{table_name}\" "

        records.each do |record_hash|
          insert_sql = "INSERT INTO #{table_name} (#{record_hash.keys.join(',')})"
          insert_sql2 = " VALUES (#{record_hash.values.collect{ |value| ActiveRecord::Base.connection.quote(value) }.join(',')})"
          insert_sql << insert_sql2
          #            puts "insert_sql = #{insert_sql}"
          dev_conn.execute insert_sql
        end
      end
    end
  end

  namespace :test do

    desc 'Drop the test master  DB'
    task :drop_master => [:environment] do
      config = ActiveRecord::Base.configurations['test']
      local_database?(config) {  drop_database(config)}
    end

    desc 'Create the test master DB'
    task :create_master => [:environment] do
      config = ActiveRecord::Base.configurations['test']
      local_database?(config) {  create_database(config)}
    end

    # TODO: MUST OVERRIDE db:test:prepare cuz it's called by 'rake
    # spec'
    # TODO: remote DB classes (RemoteMediacast and
    # RemoteDataWarehouse) must use the test DB
    task :prepare => [:environment, :drop_master, :create_master] do
      desc "Prepare the test master DB"
      #    task :prepare_master => [:environment, :drop_master,  :create_master] do

      client_file = "#{Rails.root}/db/schema.rb"
      wh_file = "#{Rails.root}/db/warehouse_schema.rb"
      mc_file = "#{Rails.root}/db/mediacast_schema.rb"
      if File.exists?(wh_file) && File.exists?(mc_file) && File.exists?(client_file)
        ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['test'])
        puts "Loading the warehouse schema"
        load(wh_file)
        puts "Loading the mediacast schema"
        load(mc_file)
        puts "Loading the client_portal schema"
        load(client_file)
        load(mc_file)
      else
        puts "Failed to prepare the master test db"
        abort "#{file} doesn't exist"
      end
    end

    desc "Reset the test databases"
    task :reset do

      #        db_config = "#{Rails.root}/config/local_database.yml"
      #        if FileTest.exist? db_config
      #          puts "Copying #{db_config.split('/').last} to database.yml"
      #          FileUtils.cp db_config, "#{Rails.root}/config/database.yml"
      #        end

      Rake::Task[:environment].execute

      # Init the test warehouse DB
      ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['test_datawarehouse'])
      puts 'Drop and Create the Test Warehouse DB'
      %w{db:test:drop:datawarehouse db:test:create:datawarehouse db:schema:load:test_datawarehouse }.each do |t|
        puts "  Executing Task #{t}"
        Rake::Task[t].execute
      end

      # Init the test mediacast DB
      ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['test_mediacast'])
      puts 'Drop and Create the Test Mediacast DB'
      %w{db:test:drop:mediacast db:test:create:mediacast db:schema:load:test_mediacast }.each do |t|
        puts "  Executing Task #{t}"
        Rake::Task[t].execute
      end

      puts 'Drop and Create the Test DB'
      test_db = ActiveRecord::Base.configurations['test']
      local_database?(test_db) do
        drop_database(test_db)
        create_database(test_db)
      end

      puts "Prepare the Test DB"
      puts "  Executing Task db:test:prepare"
      Rake::Task['db:test:prepare'].execute
    end
  end

end
