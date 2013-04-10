require_dependency 'sort_helper'

module SortHelperPatch

  def self.included(base)
    base.send(:extend, ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      #alias_method_chain :sort_update, :time_tracker
      #alias_method_chain :sort_link, :time_tracker
    end
  end

  module ClassMethods
  end

  module InstanceMethods
    #def sort_update_with_time_tracker(criteria, sort_name=nil)
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

    #def sort_link_with_time_tracker(column, caption, default_order)
    def tt_sort_link(sort_arg, column, caption, default_order)
      css, order = nil, default_order

      tt_sort_criteria = @sort_logs_criteria if sort_arg == :sort_logs
      tt_sort_criteria = @sort_bookings_criteria if sort_arg == :sort_bookings
      if column.to_s == tt_sort_criteria.first_key
        if tt_sort_criteria.first_asc?
          css = 'sort asc'
          order = 'desc'
        else
          css = 'sort desc'
          order = 'asc'
        end
      end
      caption = column.to_s.humanize unless caption

      sort_options = { sort_arg => tt_sort_criteria.add(column.to_s, order).to_param }
      url_options = params.merge(sort_options)

      # Add project_id to url_options
      url_options = url_options.merge(:project_id => params[:project_id]) if params.has_key?(:project_id)

      link_to_content_update(h(caption), url_options, :class => css)
    end

    def tt_sort_header_tag(sort_arg, column, options = {})
      caption = options.delete(:caption) || column.to_s.humanize
      default_order = options.delete(:default_order) || 'asc'
      options[:title] = l(:label_sort_by, "\"#{caption}\"") unless options[:title]
      content_tag('th', tt_sort_link(sort_arg, column, caption, default_order), options)
    end
  end
end

SortHelper.send(:include, SortHelperPatch)