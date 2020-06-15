require File.expand_path('../../../../../test_helper', __FILE__)

class Redmine::Helpers::IssuesBoardHelperTest < Redmine::HelperTest
  include ERB::Util
  include Rails.application.routes.url_helpers
  include Redmine::I18n

  fixtures :users,
           :projects,
           :roles,
           :members,
           :member_roles,
           :enumerations,
           :issues,
           :issue_statuses,
           :issue_relations,
           :issue_categories,
           :versions,
           :trackers,
           :projects_trackers,
           :enabled_modules,
           :workflows

  def setup
    User.current = User.find(1)
  end

  def test_initialize
    with_settings :gantt_items_limit => 500 do
      issues_board = Redmine::Helpers::IssuesBoard.new
      assert_equal 500, issues_board.issues_limit
      assert_equal false, issues_board.truncated
    end
  end

  def test_initialize_with_issues_limit
    with_settings :gantt_items_limit => 500 do
      issues_board = Redmine::Helpers::IssuesBoard.new({:issues_limit => 100})
      assert_equal 100, issues_board.issues_limit
      assert_equal false, issues_board.truncated
    end
  end

  def test_set_issue_query
    issues_board = Redmine::Helpers::IssuesBoard.new
    issue_query = IssueQuery.new
    issues_board.query = issue_query
    assert_equal issue_query, issues_board.query
  end

  def test_update_trancated
    issues_limit = 100
    with_settings :gantt_items_limit => issues_limit do
      issues_board = Redmine::Helpers::IssuesBoard.new({:issues_limit => 100})
      query = IssueQuery.new

      query.stubs(:issue_count).returns(issues_limit - 1)
      issues_board.query = query
      assert_equal false, issues_board.truncated

      query.stubs(:issue_count).returns(issues_limit)
      issues_board.query = query
      assert_equal false, issues_board.truncated

      query.stubs(:issue_count).returns(issues_limit + 1)
      issues_board.query = query
      assert_equal true, issues_board.truncated
    end
  end

  def test_board_statuses_with_project
    issues_board = Redmine::Helpers::IssuesBoard.new()
    query = IssueQuery.new()
    project = Project.find(1)
    query.project = project
    issues_board.query = query

    assert_equal project.rolled_up_statuses.where(:is_closed => false), issues_board.board_statuses
  end

  def test_board_statuses_without_project
    issues_board = Redmine::Helpers::IssuesBoard.new()
    query = IssueQuery.new()
    issues_board.query = query

    assert_equal IssueStatus.all.sorted.where(:is_closed => false), issues_board.board_statuses
  end

  def test_issues
    issues_limit = 3
    issues_board = Redmine::Helpers::IssuesBoard.new({:issues_limit => issues_limit})
    query = IssueQuery.new(:filters => { :status_id => {:operator => "*", :values => [""] } } )

    issues_board.query = query
    assert_equal issues_limit, issues_board.issues.count
  end
end

