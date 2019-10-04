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

    def drop_table(table_name)
      ActiveRecord::Base.connection.execute(
        <<-SQL
          DROP TABLE #{table_name}
        SQL
      )
    end

    def create_timelines_table
      ActiveRecord::Base.connection.execute(
        <<-SQL
          CREATE TABLE IF NOT EXISTS timelines (
            id INTEGER PRIMARY KEY,
            uuid string NOT NULL,
            transaction_start datetime NOT NULL,
            transaction_stop datetime NOT NULL
          )
        SQL
      )
    end

    def create_timeline_events_table
      ActiveRecord::Base.connection.execute(
        <<-SQL
          CREATE TABLE IF NOT EXISTS timeline_events (
            id INTEGER PRIMARY KEY,
            timeline_id INTEGER,
            version_id INTEGER,
            version_type STRING,
            FOREIGN KEY(timeline_id) REFERENCES timelines(id)
          )
        SQL
      )
    end
  end
end
