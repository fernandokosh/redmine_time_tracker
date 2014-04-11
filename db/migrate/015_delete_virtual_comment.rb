class DeleteVirtualComment < ActiveRecord::Migration
  def up
    remove_column :time_bookings, :virtual
    drop_table :virtual_comments
  end

  def down
    create_table :virtual_comments do |t|
      t.integer :time_booking_id
      t.string :comments
    end

    add_column :time_bookings, :virtual, :boolean, :default => false
    TimeBooking.update_all ["virtual = ?", false]
  end
end
