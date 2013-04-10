class CreateTimeLogs < ActiveRecord::Migration
  def self.up
    create_table :time_logs do |t|
      t.column :user_id, :integer
      t.column :started_on, :datetime
      t.column :stopped_at, :datetime
      t.column :project_id, :integer, :default => nil
      t.column :comments, :string
    end
  end

  def self.down
    drop_table :time_logs
  end
end
