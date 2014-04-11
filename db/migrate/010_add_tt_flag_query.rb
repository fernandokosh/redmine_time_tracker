class AddTtFlagQuery < ActiveRecord::Migration
  def up
    add_column "#{Query.table_name}", :tt_query, :boolean, :default => false
    Query.all.each do |q|
      q.update_attribute(:tt_query, false)
    end
  end

  def down
    Query.all.each do |q|
      q.destroy if q.tt_query?
    end
    remove_column "#{Query.table_name}", :tt_query
  end
end