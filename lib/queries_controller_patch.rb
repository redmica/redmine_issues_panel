require_dependency 'queries_controller'

module IssuesBoard
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
        if params[:issues_board]
          if @project
            redirect_to project_issues_board_path(@project, options)
          else
            redirect_to issues_board_path(options)
          end
        else
          super
        end
      end
    end
  end
end

QueriesController.send(:include, IssuesBoard::QueriesControllerPatch) unless QueriesController.included_modules.include? IssuesBoard::QueriesControllerPatch
