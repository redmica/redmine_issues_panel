class IssuesPanelController < ApplicationController
  before_action :find_optional_project, :except => [:show_issue_description]
  before_action :find_issue_card, :only => [:show_issue_description, :move_issue_card]

  rescue_from Query::StatementInvalid, :with => :query_statement_invalid

  helper :projects
  helper :issues
  helper :queries
  helper :watchers
  helper :custom_fields
  include QueriesHelper

  def index
    retrieve_issue_panel(params)
  end

  def show_issue_description
    render :layout => false
  end

  def move_issue_card
    if flash[:error].nil?
      @issue_card.init_journal(User.current)
      @issue_card.move!(params)
    end
  rescue Exception => e
    flash.now[:error] = e.message
  ensure
    retrieve_issue_panel
    render :layout => false
  end

  def new_issue_card
    @issue_card = IssueCard.new
    @issue_card.project = @project
    @issue_card.project ||= @issue_card.allowed_target_projects.first
    @issue_card.author ||= User.current
    @issue_card.start_date ||= User.current.today if Setting.default_issue_start_date_to_creation_date?
    attrs = (params[:issue] || {}).deep_dup
    @issue_card.instance_variable_set(:@safe_attribute_names, ['project_id', 'tracker_id', 'status_id', 'category_id', 'assigned_to_id', 'priority_id', 'fixed_version_id', 'subject', 'is_private'])
    @issue_card.safe_attributes = attrs
    @allowed_statuses = @issue_card.new_statuses_allowed_to(User.current)
    @priorities = IssuePriority.active
  end

  private

  def find_issue_card
    @issue_card = IssueCard.find(params[:id])
    raise Unauthorized unless @issue_card.visible?
  rescue ActiveRecord::RecordNotFound
    @issue_card = IssueCard.new
    flash.now[:error] = l(:error_issue_not_found_in_project)
  rescue Unauthorized
    flash.now[:error] = l(:notice_not_authorized_to_change_this_issue)
  end

  def retrieve_issue_panel(params={})
    @issues_panel = Redmine::Helpers::IssuesPanel.new(params)
    retrieve_query
    # retrieve optional query filter in session
    session_key = IssueQuery.name.underscore.to_sym
    if session[session_key]
      if params[:set_filter] && params[:query] && params[:query][:issues_num_per_row]
        session[session_key][:issues_num_per_row] = @query.issues_num_per_row
      elsif params[:query_id].blank? && session[session_key][:issues_num_per_row]
        @query.issues_num_per_row = session[session_key][:issues_num_per_row]
      end
    end
    @issues_panel.query = @query
  end
end
