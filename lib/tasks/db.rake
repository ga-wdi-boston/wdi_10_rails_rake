require 'csv'

namespace :db do
  # Make a connection with the postgresql and my development database
  def get_connection
    ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['development'])
    ActiveRecord::Base.connection
  end

  task :import => :environment do
     Rake::Task["db:drop"].invoke
     Rake::Task["db:create"].invoke
     Rake::Task["db:migrate"].invoke

    conn = get_connection
    in_filename = 'db_dump.csv'

    record_hash = { }

    CSV.foreach(in_filename) do |row|
      # puts "row is #{row}"
      table_name = 'users'
      record_hash['name'] = row.first
      record_hash['email'] = row.last

      # Construct SQL
      insert_sql = "INSERT INTO #{table_name} (#{record_hash.keys.join(',')})"
      insert_sql2 = " VALUES (#{record_hash.values.collect{ |value| ActiveRecord::Base.connection.quote(value) }.join(',')})"
      insert_sql << insert_sql2

      puts "executing insert: #{insert_sql}"
      conn.execute(insert_sql)
    end
  end # end db:import

  # Export all of the Data in the DB to a CSV file.
  task :export => :environment do
    conn = get_connection
    sql = "SELECT * FROM %s"

    # Don't care about the migrations
    skip_tables = ["schema_migrations" ]

    # Don't care about the id, created_at or updated_at columns
    skip_columns = %w{ id created_at updated_at }

    # get all the DB tables except for schema_migrations
    tables = ActiveRecord::Base.connection.tables - skip_tables

    # for every table
    tables.each do |table_name|
      puts "table name = #{table_name}"

      # Get the class, ActiveRecord Model, that maps to this table.
      # 'users' => User class
      klass = table_name.singularize.classify.constantize

      # invoke the SQL SELECT to get data
      # sql % table_name is a short cut to combine two
      # string. More info in sprintf about how we
      # can format the right hand side (RHS) string
      # sql = "SELECT * FROM %s"
      table = conn.select_all(sql % table_name)

      # All the rows from this table
      # An Array of Hashes where each hash represents one
      # table row
      row_hashes = table.to_hash

      # Where to save the data
      out_filename = 'db_dump.csv'

      # Open and create the CSV file
      CSV.open('db_dump.csv', 'w') do |csv|

        row_hashes.each do |row_hash|
          # each row in the table
          clean_row = row_hash.except(*skip_columns)
          puts "clean_row is #{clean_row}"

          # remove nils with compact
          attrs = clean_row.values.compact

          # attrs of a single Model instance
          puts "attrs = #{attrs}"

          # push attrs to csv
          csv << attrs
        end
      end
    end

  end # end db:export

end
