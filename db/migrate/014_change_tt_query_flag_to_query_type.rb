class ChangeTtQueryFlagToQueryType < ActiveRecord::Migration
  def up
    add_column "#{Query.table_name}", :tt_query_type, :Integer, :default => 0
    Query.all.each do |q|
      # all previously save tt_query queries have to be removed
      if q.tt_query?
        q.destroy
      else # otherwise they are normal redmine queries and should be set default
        q.update_attribute(:tt_query_type, 0)
      end
    end
    # tt_query-flag is deprecated
    remove_column "#{Query.table_name}", :tt_query
  end

  def down
    # we have to delete all non-standard redmine queries
    Query.all.each do |q|
      q.destroy if q.tt_query_type != 0
    end
    remove_column "#{Query.table_name}", :tt_query_type
    # we have to reestablish the old db-state
    add_column "#{Query.table_name}", :tt_query, :boolean, :default => false
    Query.all.each do |q|
      q.update_attribute(:tt_query, false)
    end
  end
end