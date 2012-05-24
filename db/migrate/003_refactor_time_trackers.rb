class RefactorTimeTrackers < ActiveRecord::Migration
  def self.up
    drop_table :timet_rackers
    create_table :time_trackers do |t|
      t.column :user_id, :integer
      t.column :started_on, :datetime
    end
  end

  def self.down
    drop_table :time_trackers
    # due to compatibility to the original time_tracker plugin we have to restore the original database-structure
    create_table :time_trackers do |t|
      t.column :user_id, :integer
      t.column :issue_id, :integer
      t.column :started_on, :datetime
    end
    add_column :time_trackers, :time_spent, :float, :default => 0
    add_column :time_trackers, :paused, :boolean, :default => false
  end
end
