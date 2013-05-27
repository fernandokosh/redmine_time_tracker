module TtQueryOperators
  # following two methods are a workaround to implement some custom filters to the date-filter without rewriting
  # Query-class and JS-methods for filter-build completely
  def self.operators_labels
    super.merge '!*' => l(:time_tracker_label_this_month)
  end

  def self.operators_by_filter_type
    super.merge :date => %w(= >< t w !* *)
  end
end
