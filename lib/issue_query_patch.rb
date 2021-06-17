require_dependency 'issue_query'

module IssuesPanel
  module IssueQueryPatch
    def self.included(base)
      base.send(:prepend, InstanceMethods)
      base.class_eval do
        #unloadable
      end
    end

    module InstanceMethods
      def build_from_params(params, defaults={})
        super
        self.issues_num_per_row =
          params[:issues_num_per_row] ||
            (params[:query] && params[:query][:issues_num_per_row]) ||
            options[:issues_num_per_row]
        self
      end

      def issues_num_per_row
        r = options[:issues_num_per_row]
        r.to_i == 0 ? 1 : r.to_i
      end

      def issues_num_per_row=(arg)
        options[:issues_num_per_row] = arg ? arg.to_i : 1
      end
    end
  end
end

Rails.configuration.to_prepare do
  IssueQuery.include IssuesPanel::IssueQueryPatch
end
