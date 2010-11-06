class AddPauseSupport < ActiveRecord::Migration
  def self.up
    add_column :time_trackers, :time_spent, :float, :default => 0
    add_column :time_trackers, :paused, :boolean, :default => false
  end

  def self.down
    remove_column :time_trackers, :time_spent
    remove_column :time_trackers, :paused
  end
end
