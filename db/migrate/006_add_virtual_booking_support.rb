class AddVirtualBookingSupport < ActiveRecord::Migration
  def up
    add_column :time_bookings, :virtual, :boolean, :default => false
    TimeBooking.update_all ["virtual = ?", false]
  end

  def down
    remove_column :time_bookings, :virtual
  end
end
