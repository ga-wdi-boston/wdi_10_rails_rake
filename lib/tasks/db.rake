require 'csv'

namespace :db do
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
      puts "row is #{row}"
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

  task :export => :environment do
    conn = get_connection
    sql = "SELECT * FROM %s"

    skip_tables = ["schema_migrations" ]

    # get all the DB tables except for schema_migrations
    tables = ActiveRecord::Base.connection.tables - skip_tables

    # for every table
    tables.each do |table_name|
      puts "table name = #{table_name}"

      # Get the class, ActiveRecord Model, that maps to this table.
      klass = table_name.singularize.classify.constantize
      # klass.delete_all

      # invoke the SQL SELECT to get data
      table = conn.select_all(sql % table_name)

      # All the rows from this table
      rows = table.rows

      # Where to save the data
      out_filename = 'db_dump.csv'

      CSV.open('db_dump.csv', 'w') do |csv|

        rows.each do |row|
          # TODO: to specific to the Users table
          # don't save :id, :created_at and :updated_at columns
          attrs = row[1..2]
          csv << attrs
          # klass.create!(row)
        end
        puts "Exported #{rows.size} rows from #{klass} to #{out_filename}"
      end
    end

  end # end db:export

end
