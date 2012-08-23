require_dependency 'context_menus_controller'

module ContextMenusControllerControllerPatch

  def self.included(base)
    base.send(:extend, ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
    end
  end

  module ClassMethods
  end

  module InstanceMethods

    # actual implementation will support single-selection only!
    def tt_overview
      entryClass = params[:entryClass] # specify either a TimeLog- or TimeBooking- ContextMenu was activated

      if entryClass == "TimeLog"
        # book / edit / delete
        @time_log = TimeLog.where(:id => params[:ids][0]).first
      elsif entryClass == "TimeBooking"
        # continue (nur bei singleSelect) / edit / delete
        @time_booking = TimeBooking.where(:id => params[:ids][0]).first
      end

      render :layout => false
    end
  end
end

ContextMenusController.send(:include, ContextMenusControllerControllerPatch)