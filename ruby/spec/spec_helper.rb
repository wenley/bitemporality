require 'bundler/setup'
Bundler.setup

require 'bitemporal'
require 'database_cleaner'
require 'support/spec_tables'

RSpec.configure do |config|
  config.before(:suite) do
    make_sqlite_database
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end

def make_sqlite_database
  FileUtils.mkdir_p 'tmp/db/'

  ActiveRecord::Base.establish_connection(
    adapter:  'sqlite3',
    database: 'tmp/db/test.sqlite3',
  )
end
