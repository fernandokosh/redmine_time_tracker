class AddVirtualBookingSupport < ActiveRecord::Migration
  change_table :time_bookings do |t|
    t.boolean :virtual, :default => false
  end
  TimeBooking.update_all ["virtual = ?", false]
end