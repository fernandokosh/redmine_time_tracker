class CreateTimeTrackers < ActiveRecord::Migration
  def self.up
    create_table :time_trackers do |t|
      t.column :user_id, :integer
      t.column :issue_id, :integer
      t.column :started_on, :datetime
    end
  end

  def self.down
    drop_table :time_trackers
  end
end
