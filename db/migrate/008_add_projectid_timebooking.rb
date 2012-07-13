class AddProjectidTimebooking < ActiveRecord::Migration
  def up
    add_column :time_bookings, :project_id, :integer
    TimeBooking.all.each do |tb|
      if tb.virtual
        tb.update_attribute(:project_id, tb.time_log.project_id)
      else
        tb.update_attribute(:project_id, tb.time_entry.project_id)
      end
    end
  end

  def down
    remove_column :time_bookings, :project_id
  end
end