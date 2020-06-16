module Redmine
  module Helpers
    # Simple class to handle isses board data
    class IssuesBoard
      include ERB::Util
      include Rails.application.routes.url_helpers
      include Redmine::I18n

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

      def board_statuses
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

      def render_column_content(column, issue)
        return '' if column.name == :id || column.name == :status || column == @query.group_by_column
        caption = "<strong>#{column.caption}: </strong>"
        value = +''

        case column.name
        when :author
          value = view.avatar(issue.author, :size => "13") + " " + view.link_to_user(issue.author)
        when :assigned_to
          value = issue.assigned_to ? view.assignee_avatar(issue.assigned_to, :size => "13") + " " + view.link_to_user(issue.assigned_to) : "-"
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
          :class => "hascontextmenu #{issue.closed? ? 'closed' : ''}"
        ).html_safe
      end

      def render_issues_board
        statuses = self.board_statuses

        thead = +''
        thead << view.content_tag('thead',
                   view.content_tag('tr',
                     statuses.collect {|s| view.content_tag('th', s)}.join.html_safe
                   )
                 )

        if self.grouped?
          grouped_issues = self.issues.group_by { |issue| query.group_by_column.group_value(issue) }
        end
        grouped_issues ||= {nil => self.issues}

        tbody = +''
        grouped_issues.each do |group, issues_in_group|
          next if issues_in_group.nil?

          if self.grouped?
            if group.nil?
              group_name = "(#{l(:label_blank_value)})"
            else
              group_name = view.format_object(group)
            end
            tbody << view.content_tag('tr',
                       view.content_tag('td',
                         view.content_tag('span', '&nbsp;'.html_safe, :class => 'expander icon icon-expended', :onclick => 'toggleRowGroup(this);').html_safe +
                         view.content_tag('span', group_name, :class => 'name').html_safe +
                         view.content_tag('span', issues_in_group.count, :class => 'badge badge-count count').html_safe,
                         :colspan => statuses.count
                       ),
                       :class => 'group open'
                     ).html_safe
          end

          td_tags = +''
          issues_group_by_status = issues_in_group.group_by { |issue| issue.status }
          column_names = @query.inline_columns.collect{ |c| c.name }
          statuses.each do |status|
            issue_cards = +''
            if issues_in_status = issues_group_by_status[status]
              issues_in_status.each do |issue|
                issue_cards << view.content_tag('div',
                                 render_card_content(issue),
                                 :class => "issue-card",
                                 :id => "issue-card-#{issue.id}",
                                 :data => { :issue_id => issue.id }
                               )
              end
            end

            group_id = ''
            move_params = { :status_id => status.id }
            if self.grouped?
              if @query.group_by_column.instance_of?(QueryColumn)
                case @query.group_by_column.name
                when :project, :tracker, :status, :priority, :assigned_to, :category, :fixed_version
                  group_id = group.try(:id).to_s
                  move_params.merge!({ :group_key => "#{@query.group_by}_id", :group_value => group_id })
                when :author
                  group_id = group.try(:id).to_s
                  # can't move between groups (because author can't change).
                else
                  group_id = group.to_s
                  move_params.merge!({ :group_key => @query.group_by, :group_value => group_id })
                end
              elsif @query.group_by_column.instance_of?(QueryCustomFieldColumn)
                group_id = group.to_s
                move_params.merge!({ :group_key => :custom_field_values, :group_value => "#{@query.group_by_column.custom_field.id},#{group_id}" })
              else # eg: TimestampQueryColumn
                group_id = group.to_s
                # can't move between groups (because created_at, updated_on and closed_on can't change).
              end

              if @query.group_by_column.instance_of?(TimestampQueryColumn) || @query.group_by_column.name == :author
                move_params.merge!({ :movable_area => ".issue-card-receiver-#{group_id}" })
              else
                move_params.merge!({ :movable_area => ".issue-card-receiver" })
              end
            else
              move_params.merge!({ :movable_area => ".issue-card-receiver" })
            end

            td_tags << view.content_tag('td',
                         issue_cards.html_safe,
                         :class => "issue-card-receiver issue-card-receiver-#{group_id}",
                         :id => "issue-card-receiver-#{group_id}-#{status.id}",
                         :data => move_params
                       ).html_safe
          end

          tbody << view.content_tag('tr', td_tags.html_safe)
        end

        view.content_tag('table', thead.html_safe + tbody.html_safe, :id => 'issues_board', :class => 'issues-board list issues').html_safe
      end
    end
  end
end
