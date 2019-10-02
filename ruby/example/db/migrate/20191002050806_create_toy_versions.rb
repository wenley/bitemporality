class CreateToyVersions < ActiveRecord::Migration[6.0]
  def change
    create_table :toy_versions do |t|
      t.datetime :effective_start
      t.datetime :effective_stop
      t.string :uuid

      t.index :effective_start
      t.index :effective_stop
      t.index :uuid, unique: true

      t.timestamps
    end
  end
end
