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
    if flash[:error].nil?
      render json: { description: render_to_string(partial: 'issues_panel/show_issue_description', locals: { issue_card: @issue_card }) }
    else
      render json: { error_message: flash[:error] }
    end
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
    retrieve_default_query(true)
    retrieve_query(IssueQuery, true)
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

  # This method is based on IssuesController#retrieve_default_query
  # and should be kept in sync with the Redmine core implementation.
  def retrieve_default_query(use_session)
    return if params[:query_id].present?
    return if api_request?
    return if params[:set_filter]

    if params[:without_default].present?
      params[:set_filter] = 1
      return
    end

    if !params[:set_filter] && use_session && session[:issue_query]
      # Don't apply the default query if a valid query id is set in the session
      query_id, project_id = session[:issue_query].values_at(:id, :project_id)
      return if query_id && project_id == @project&.id && IssueQuery.exists?(id: query_id)
    end

    if (default_query = IssueQuery.default(project: @project))
      params[:query_id] = default_query.id
    end
  end
end
