class AddTtActivity < ActiveRecord::Migration
  def up
    tea = TimeEntryActivity.where(:name => :time_tracker_activity).first
    TimeEntryActivity.create(:name => :time_tracker_activity, :active => true) if tea.nil?
  end

  def down
    tea = TimeEntryActivity.where(:name => :time_tracker_activity).first
    TimeEntryActivity.destroy(tea.id) unless tea.nil?
  end
end