require_dependency 'queries_controller'

module IssuesPanel
  module QueriesControllerPatch
    def self.included(base)
      #base.send(:include, InstanceMethods)
      base.send(:prepend, InstanceMethods)
      base.class_eval do
        #unloadable
      end
    end

    module InstanceMethods
      def redirect_to_issue_query(options)
        if params[:issues_panel]
          if @project
            redirect_to project_issues_panel_path(@project, options)
          else
            redirect_to issues_panel_path(options)
          end
        else
          super
        end
      end
    end
  end
end

QueriesController.send(:include, IssuesPanel::QueriesControllerPatch) unless QueriesController.included_modules.include? IssuesPanel::QueriesControllerPatch
