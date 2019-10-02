class CreateTimelineEvents < ActiveRecord::Migration[6.0]
  def change
    create_table :timeline_events do |t|
      t.references :timeline, null: false, foreign_key: true
      t.references :version, null: false, foreign_key: true

      t.timestamps
    end
  end
end
