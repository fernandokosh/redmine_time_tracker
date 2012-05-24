class CreateTimeBookings < ActiveRecord::Migration
  def self.up
    create_table :time_bookings do |t|
      t.column :time_log_id, :integer
      t.column :time_entry_id, :integer
      t.column :started_on, :datetime
      t.column :stopped_at, :datetime
    end
  end

  def self.down
    drop_table :time_bookings
  end
end
