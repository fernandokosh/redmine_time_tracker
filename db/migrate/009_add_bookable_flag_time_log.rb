class AddBookableFlagTimeLog < ActiveRecord::Migration
  def up
    add_column :time_logs, :bookable, :boolean, :default => true
    TimeLog.all.each do |tl|
      tl.update_attribute(:bookable, (tl.bookable_hours > 0))
    end
  end

  def down
    remove_column :time_logs, :bookable
  end
end