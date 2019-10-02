class CreateTimelines < ActiveRecord::Migration[6.0]
  def change
    create_table :timelines do |t|
      t.datetime :transaction_start
      t.datetime :transaction_stop
      t.string :uuid

      t.index :uuid, unique: true
      t.index :transaction_start
      t.index :transaction_stop

      t.timestamps
    end
  end
end
