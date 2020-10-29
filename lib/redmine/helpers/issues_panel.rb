module Redmine
  module Helpers
    # Simple class to handle isses panel data
    class IssuesPanel
      include ERB::Util
      include Rails.application.routes.url_helpers
      include Redmine::I18n
      include IssuesPanelHelper

      attr_reader :truncated, :issues_limit
      attr_accessor :query, :view

      def initialize(options={})
        options = options.dup
        if options.has_key?(:issues_limit)
          @issues_limit = options[:issues_limit]
        else
          @issues_limit = Setting.gantt_items_limit.blank? ? nil : Setting.gantt_items_limit.to_i
        end
        @truncated = false
      end

      def query=(query)
        @query = query
        query.available_columns.delete_if { |c| c.name == :tracker }
        @truncated = @query.issue_count.to_i > @issues_limit.to_i
      end

      def panel_statuses
        # IssueStatus.where(:id => @query.issues.pluck(:status_id).uniq)
        if @query.project
          statuses = @query.project.rolled_up_statuses
        else
          statuses = IssueStatus.all.sorted
        end
        if filterd_statuses = @query.filters["status_id"]
          operator = filterd_statuses[:operator].to_s
          values = filterd_statuses[:values].reject(&:blank?)
          case operator
          when "o"
            statuses = statuses.where(:is_closed => false)
          when "c"
            statuses = statuses.where(:is_closed => true)
          when "="
            statuses = statuses.select{|status| values.include?(status.id.to_s) }
          when "!"
            statuses = statuses.select{|status| values.exclude?(status.id.to_s) }
          #when "*"
            # nothing to change statuses
          end
        end
        statuses
      end

      def issues
        @query.issues(:limit => @issues_limit)
      end

      def grouped?
        @query && @query.grouped? && @query.group_by_column.name != :status
      end

      def grouped_issues
        if self.grouped?
          self.issues.group_by { |issue| query.group_by_column.group_value(issue) }
        else
          {nil => self.issues}
        end.each do |group, issues_in_group|
          if group.nil?
            group_value = ''
            group_label = "(#{l(:label_blank_value)})"
          else
            if @query.group_by_column.instance_of?(QueryColumn) &&
               [:project, :tracker, :status, :priority, :assigned_to, :category, :fixed_version, :author].include?(@query.group_by_column.name)
              group_value = group.try(:id).to_s
            elsif @query.group_by_column.instance_of?(QueryCustomFieldColumn) &&
               [:user, :version, :enumeration].include?(@query.group_by_column.custom_field.field_format.to_sym)
              group_value = group.try(:id).to_s
            else
              group_value = group.to_s
            end
            group_label = view.format_object(group)
          end
          group_css = group_value.gsub(' ', '-')
          yield group_value, group_label, group_css, issues_in_group.count, issues_in_group.group_by { |issue| issue.status }
        end
      end

      def move_params(group_value, status)
        params = { :status_id => status.id }
        if self.grouped?
          if @query.group_by_column.instance_of?(QueryColumn)
            case @query.group_by_column.name
            when :project, :tracker, :status, :priority, :assigned_to, :category, :fixed_version
              params.merge!({ :group_key => "#{@query.group_by}_id", :group_value => group_value })
            when :author
              # can't move between groups (because author can't change).
            else
              params.merge!({ :group_key => @query.group_by, :group_value => group_value })
            end
          elsif @query.group_by_column.instance_of?(QueryCustomFieldColumn)
            params.merge!({ :group_key => :custom_field_values, :group_value => "#{@query.group_by_column.custom_field.id},#{group_value}" })
          else # eg: TimestampQueryColumn
            # can't move between groups (because created_at, updated_on and closed_on can't change).
          end

          if @query.group_by_column.instance_of?(TimestampQueryColumn) || @query.group_by_column.name == :author
            # can't move to other groups
            params.merge!({ :movable_area => ".issue-card-receivers-#{group_value}" })
          else
            # enable to move other groups
            params.merge!({ :movable_area => ".issue-panel" })
          end
        else
          # enable to move other groups
          params.merge!({ :movable_area => ".issue-panel" })
        end
        params
      end


      def render_column_content(column, issue)
        return '' if column.name == :id || column.name == :status || column == @query.group_by_column
        caption = "<strong>#{column.caption}: </strong>"
        value = +''

        case column.name
        when :author
          value = view.avatar(issue.author, :size => "13") + " " + view.link_to_user(issue.author)
        when :assigned_to
          value = issue.assigned_to ? view.assignee_avatar(issue.assigned_to, :size => "13") + " " + view.link_to_user(issue.assigned_to) : "-"
        when :due_date
          value = view.issue_due_date_details(issue) || ''
        else
          value = view.column_content(column, issue) || ''
        end
        view.content_tag('div',
          view.content_tag('div', caption.html_safe, :class => "caption").html_safe +
          view.content_tag('div', value.html_safe, :class => "value").html_safe,
          :class => "#{column.css_classes} clear"
        ).html_safe
      end

      def render_card_content(issue)
        view.content_tag('div',
          view.content_tag('div',
            view.content_tag('input', nil, :type => 'checkbox', :name => 'ids[]', :value => issue.id, :style => 'display:none;', :class => 'toggle-selection').html_safe +
            view.content_tag('div',
              view.link_to_context_menu.html_safe +
              view.link_to_issue(issue, :tracker => true, :subject => false).html_safe,
              :class => 'header clear'
            ).html_safe +
            @query.inline_columns.collect do |column|
              render_column_content(column, issue)
            end.join.html_safe +
            view.content_tag('div',
              view.watcher_link(issue, User.current),
              :class => 'footer clear').html_safe, 
            :class => "card-content"),
          :id => "issue-#{issue.id}",
          :class => "hascontextmenu #{issue.priority.try(:css_classes)} #{issue.overdue? ? 'overdue' : ''} #{issue.closed? ? 'closed' : ''}"
        ).html_safe
      end

      def render_issue_cards(issues_in_status, status, group_value)
        issue_cards = +''
        (issues_in_status || []).each do |issue|
          issue_cards << view.content_tag('div',
                           render_card_content(issue),
                           :class => "issue-card link-issue",
                           :id => "issue-card-#{issue.id}",
                           :data => { :issue_id => issue.id, :status_id => status.id, :group_value => group_value }
                         )
        end
        if issue = Issue.new(:project => @query.project)
          issue.project ||= issue.allowed_target_projects.first
          issue.tracker ||= issue.allowed_target_trackers.first
          if issue.new_statuses_allowed_to(User.current).include?(status)
            new_issue_params = {:status_id => status.id}
            new_issue_params[:"#{@query.group_by}_id"] = group_value if @query.grouped?
            issue_cards << view.content_tag('div',
                             view.link_to(l(:label_issue_new),
                               view.new_issue_card_path({ :params => { :project_id => @query.project.try(:id), :issue => new_issue_params, :back_url => _project_issues_panel_path(@query.project) } }),
                               :remote => true,
                               :class => 'icon icon-add new-issue'),
                             :class => "issue-card add-issue-card",
                             :data => { :status_id => status.id, :group_value => group_value }
                           )
          end
        end
        issue_cards.html_safe
      end

      def render_issues_panel
        statuses = self.panel_statuses

        # panel header
        thead = +''
        thead << view.content_tag('thead',
                   view.content_tag('tr',
                     statuses.collect {|s|
                       view.content_tag('th',
                         s.to_s.html_safe +
                         view.content_tag('span',
                           issues_count = self.issues.select { |issue| issue.status_id == s.id }.count,
                           :id => "issues-count-on-status-#{s.id}",
                           :class => 'badge badge-count count').html_safe,
                       )}.join.html_safe
                   )
                 )

        tbody = +''
        self.grouped_issues do |group_value, group_label, group_css, group_count, issues_in_group_by_status|
          next if issues_in_group_by_status.nil?

          # group label
          if self.grouped?
            tbody << view.content_tag('tr',
                       view.content_tag('td',
                         view.content_tag('span', '&nbsp;'.html_safe, :class => 'expander icon icon-expended', :onclick => 'toggleRowGroup(this);').html_safe +
                         view.content_tag('span', group_label, :class => 'name').html_safe +
                         view.content_tag('span', group_count, :class => 'badge badge-count count issues-count-on-group', :id => "issues-count-on-group-#{group_css}").html_safe,
                         :colspan => statuses.count
                       ),
                       :class => 'group open'
                     ).html_safe
          end

          # status lanes (in group)
          td_tags = +''
          column_names = @query.inline_columns.collect{ |c| c.name }
          statuses.each do |status|
            td_tags << view.content_tag('td',
                         render_issue_cards(issues_in_group_by_status[status], status, group_value),
                         :class => "issue-card-receiver",
                         :id => "issue-card-receiver-#{group_css}-#{status.id}",
                         :data => move_params(group_value, status)
                       ).html_safe
          end

          tbody << view.content_tag('tr', td_tags.html_safe, :class => "issue-card-receivers-#{group_css}")
        end

        view.content_tag('table', thead.html_safe + tbody.html_safe, :id => 'issues_panel', :class => 'issues-panel list issues').html_safe
      end
    end
  end
end
