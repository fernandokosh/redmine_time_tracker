class RefactorTimeTrackers < ActiveRecord::Migration
  def self.up
    drop_table :time_trackers
    # only one timeTracker per user
    # every tracker can be associated to a project or a issue (issues are implicit associated to a project)
    create_table :time_trackers do |t|
      t.column :user_id, :integer
      t.column :started_on, :datetime
      t.column :comments, :string
      t.column :project_id, :integer, :default => nil
      t.column :issue_id, :integer, :default => nil
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
