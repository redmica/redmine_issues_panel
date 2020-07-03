class IssuesBoardController < ApplicationController
  before_action :find_optional_project

  rescue_from Query::StatementInvalid, :with => :query_statement_invalid

  helper :issues
  helper :queries
  helper :watchers
  include QueriesHelper

  def index
    retrieve_issue_board(params)
  end

  def move_issue_card
    @issue_card = IssueCard.find(params[:id])
    raise Unauthorized unless @issue_card.visible?
    @issue_card.init_journal(User.current)
    @issue_card.move!(params)

  rescue ActiveRecord::RecordNotFound
    @issue_card = IssueCard.new
    flash.now[:error] = l(:error_issue_not_found_in_project)
  rescue Unauthorized
    flash.now[:error] = l(:notice_not_authorized_to_change_this_issue)
  rescue Exception => e
    flash.now[:error] = e.message
  ensure
    retrieve_issue_board
    render :layout => false
  end

  private

  def retrieve_issue_board(params={})
    @issues_board = Redmine::Helpers::IssuesBoard.new(params)
    retrieve_query
    @issues_board.query = @query
  end
end
