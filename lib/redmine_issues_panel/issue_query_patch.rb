require 'issue_query'

module RedmineIssuesPanel
  module IssueQueryPatch
    def self.included(base)
      base.send(:prepend, InstanceMethods)
      base.class_eval do
        #unloadable
        attribute :use_on_issues_panel, :boolean, default: false
        self.available_columns << QueryColumn.new(:issue_card_position, :sortable => "#{IssueCardPosition.table_name}.position")
      end
    end

    module InstanceMethods
      def build_from_params(params, defaults={})
        super
        self.issues_num_per_row =
          params[:issues_num_per_row] ||
            (params[:query] && params[:query][:issues_num_per_row]) ||
            options[:issues_num_per_row]
        self.enable_manual_ordering =
          params[:enable_manual_ordering] ||
            (params[:query] && params[:query][:enable_manual_ordering]) ||
            options[:enable_manual_ordering]
        self
      end

      def base_scope
        s = super
        if (self.use_on_issues_panel? && self.enable_manual_ordering?) ||
            (self.column_names && self.column_names.include?(:issue_card_position))
          s = s.includes(:issue_card_position)
        end
        s
      end

      def issues(options={})
        if self.enable_manual_ordering?
          options[:order] = []
          if Redmine::Database.postgresql?
            options[:order] << Arel.sql("#{IssueCardPosition.table_name}.position ASC NULLS FIRST")
          else
            options[:order] << Arel.sql("#{IssueCardPosition.table_name}.position ASC")
          end
          options[:order] << Arel.sql("#{Issue.table_name}.id DESC")
        end
        super(options)
      end

      def issues_num_per_row
        r = options[:issues_num_per_row]
        r.to_i == 0 ? 1 : r.to_i
      end

      def issues_num_per_row=(arg)
        options[:issues_num_per_row] = arg ? arg.to_i : 1
      end

      def enable_manual_ordering
        options[:enable_manual_ordering]
      end

      def enable_manual_ordering?
        return false unless self.use_on_issues_panel?
        if self.enable_manual_ordering.nil?
          self.new_record? ? true : false
        else
          self.enable_manual_ordering.to_s == '1'
        end
      end

      def enable_manual_ordering=(arg)
        options[:enable_manual_ordering] = (arg.to_s == '0' ? '0' : '1')
      end
    end
  end
end

IssueQuery.include RedmineIssuesPanel::IssueQueryPatch
