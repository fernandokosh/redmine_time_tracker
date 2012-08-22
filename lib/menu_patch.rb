require_dependency 'lib/redmine/menu_manager'

# redmine only differs between project_menu and application_menu! but we want to display the
# time_tracker submenu only if the plugin specific controllers are called
module MenuPatch

  def self.included(base)
    base.send(:extend, ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      alias_method_chain :render_main_menu, :time_tracker
      alias_method_chain :display_main_menu?, :time_tracker
    end
  end

  module ClassMethods
  end

  module InstanceMethods

    def display_main_menu_with_time_tracker?(project)
      Redmine::MenuManager.items(get_menu_name(project)).children.present?
    end

    def render_main_menu_with_time_tracker(project)
      render_menu(get_menu_name(project), project)
    end

    private

    def get_menu_name(project)
      if (project && !project.new_record?)
        :project_menu
      else
        if %w(tt_overview tt_info time_list).include? params[:controller]
          :timetracker_menu
        else
          :application_menu
        end
      end
    end
  end
end

Redmine::MenuManager::MenuHelper.send(:include, MenuPatch)