class AddActivitySupport < ActiveRecord::Migration
  def self.up
    add_column :time_trackers, :activity_id, :integer
  end

  def self.down
    remove_column :time_trackers, :activity_id
  end
end
