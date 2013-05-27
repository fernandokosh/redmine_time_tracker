require_dependency 'sort_helper'

module TtSortHelper
  def tt_sort_update(sort_arg, criteria, sort_name=nil)
    sort_name ||= self.sort_name
    tt_sort_criteria = SortHelper::SortCriteria.new
    tt_sort_criteria.available_criteria = criteria
    tt_sort_criteria.from_param(params[sort_arg] || session[sort_name])
    tt_sort_criteria.criteria = @sort_default if tt_sort_criteria.empty?
    session[sort_name] = tt_sort_criteria.to_param
    @sort_logs_criteria = tt_sort_criteria.clone if sort_arg == :sort_logs
    @sort_bookings_criteria = tt_sort_criteria.clone if sort_arg == :sort_bookings
  end
end
