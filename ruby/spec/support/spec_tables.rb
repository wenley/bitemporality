module SpecTables
  class << self
    def create_versioned_addresses_table
      ActiveRecord::Base.connection.execute(
        <<-SQL
          CREATE TABLE IF NOT EXISTS versioned_addresses (
            uuid string NOT NULL,
            effective_start datetime NOT NULL,
            effective_stop datetime NOT NULL,
            street_1 TEXT
          )
        SQL
      )
    end

    def drop_versioned_addresses_table
      ActiveRecord::Base.connection.execute(
        <<-SQL
          DROP TABLE versioned_addresses
        SQL
      )
    end
  end
end
