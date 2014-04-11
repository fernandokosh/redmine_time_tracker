class AddTtActivity < ActiveRecord::Migration
  def up
    tea = TimeEntryActivity.where(:name => :time_tracker_activity).first
    TimeEntryActivity.create(:name => :time_tracker_activity, :active => true) if tea.nil?
  end

  def down
    tea = TimeEntryActivity.where(:name => :time_tracker_activity).first
    TimeEntryActivity.destroy(tea.id) unless tea.nil?
  rescue
    Rails.logger.info "Can't delete the TimeEntryActivity. There are still redmine activities booked with this."
  end
end