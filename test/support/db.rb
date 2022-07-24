# frozen_string_literal: true

ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  database: 'archiversion',
  host: 'localhost',
  port: nil,
  username: ENV.fetch('POSTGRES_USER', nil),
  password: ENV.fetch('POSTGRES_PASSWORD', nil)
)

def generate_versions_table(table_name)
  destination_root = File.expand_path('../../tmp', __dir__)
  Rails::Generators.invoke('archiversion:migration', [table_name], destination_root: destination_root)
  Dir[File.join(File.join(destination_root, 'db/migrate'), '/*.rb')].sort.each { |file| require file }
  "Create#{table_name.classify.singularize}Versions".constantize.migrate(:up)
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    next unless ActiveRecord::Base.connection.table_exists?(table)

    ActiveRecord::Base.connection.drop_table(table, force: :cascade)
  end
end
