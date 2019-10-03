require 'bundler/setup'
Bundler.setup

require 'bitemporal'

RSpec.configure do |config|

end

def make_sqlite_database
  FileUtils.mkdir_p 'tmp/db/'

  ActiveRecord::Base.establish_connection(
    adapter:  'sqlite3',
    database: 'tmp/db/test.sqlite3',
  )
end
