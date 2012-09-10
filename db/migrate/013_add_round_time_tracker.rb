class AddRoundTimeTracker < ActiveRecord::Migration
  def up
    add_column "#{TimeTracker.table_name}", :round, :boolean, :default => false
    TimeTracker.all.each do |tt|
      tt.update_attribute(:round, false)
    end
  end

  def down
    remove_column "#{TimeTracker.table_name}", :round
  end
end