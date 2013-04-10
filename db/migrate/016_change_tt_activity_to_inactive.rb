class ChangeTtActivityToInactive < ActiveRecord::Migration
  def up
    tea = TimeEntryActivity.where(:name => :time_tracker_activity).first
    if tea.nil?
      TimeEntryActivity.create(:name => :time_tracker_activity, :active => false)
    else
      tea.update_column(:active, false)
    end
  end
end