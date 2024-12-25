require File.expand_path('../../../../../test_helper', __FILE__)

class Redmine::Helpers::IssuesPanelHelperTest < Redmine::HelperTest
  include ERB::Util
  include Rails.application.routes.url_helpers
  include Redmine::I18n

  def setup
    User.current = User.find(1)
  end

  def test_initialize
    with_settings :gantt_items_limit => 500 do
      issues_panel = Redmine::Helpers::IssuesPanel.new
      assert_equal 500, issues_panel.issues_limit
      assert_equal false, issues_panel.truncated
    end
  end

  def test_initialize_with_issues_limit
    with_settings :gantt_items_limit => 500 do
      issues_panel = Redmine::Helpers::IssuesPanel.new({:issues_limit => 100})
      assert_equal 100, issues_panel.issues_limit
      assert_equal false, issues_panel.truncated
    end
  end

  def test_set_issue_query
    issues_panel = Redmine::Helpers::IssuesPanel.new
    issue_query = IssueQuery.new
    issues_panel.query = issue_query
    assert_equal issue_query, issues_panel.query
  end

  def test_update_trancated
    issues_limit = 100
    with_settings :gantt_items_limit => issues_limit do
      issues_panel = Redmine::Helpers::IssuesPanel.new({:issues_limit => 100})
      query = IssueQuery.new

      query.stubs(:issue_count).returns(issues_limit - 1)
      issues_panel.query = query
      assert_equal false, issues_panel.truncated

      query.stubs(:issue_count).returns(issues_limit)
      issues_panel.query = query
      assert_equal false, issues_panel.truncated

      query.stubs(:issue_count).returns(issues_limit + 1)
      issues_panel.query = query
      assert_equal true, issues_panel.truncated
    end
  end

  def test_panel_statuses_with_project
    issues_panel = Redmine::Helpers::IssuesPanel.new()
    query = IssueQuery.new()
    project = Project.find(1)
    query.project = project
    issues_panel.query = query

    assert_equal project.rolled_up_statuses.where(:is_closed => false), issues_panel.panel_statuses
  end

  def test_panel_statuses_without_project
    issues_panel = Redmine::Helpers::IssuesPanel.new()
    query = IssueQuery.new()
    issues_panel.query = query

    assert_equal IssueStatus.all.sorted.where(:is_closed => false), issues_panel.panel_statuses
  end

  def test_panel_statuses_with_include_tracker_filter
    WorkflowTransition.where(:tracker_id => [1, 2]).delete_all
    WorkflowTransition.create!(:role_id => 1, :tracker_id => 1, :old_status_id => 0, :new_status_id => 1)
    WorkflowTransition.create!(:role_id => 1, :tracker_id => 2, :old_status_id => 0, :new_status_id => 5)
    issues_panel = Redmine::Helpers::IssuesPanel.new()
    query = IssueQuery.new()
    query.filters = {'tracker_id' => {:operator => "=", :values => [1, 2]}}
    issues_panel.query = query

    assert_equal IssueStatus.all.sorted.where(id: [0, 1, 5]), issues_panel.panel_statuses
  end

  def test_panel_statuses_with_exclude_tracker_filter
    WorkflowTransition.where(:tracker_id => 3).delete_all
    WorkflowTransition.create!(:role_id => 1, :tracker_id => 3, :old_status_id => 1, :new_status_id => 2)
    issues_panel = Redmine::Helpers::IssuesPanel.new()
    query = IssueQuery.new()
    query.filters = {'tracker_id' => {:operator => "!", :values => [1, 2]}}
    issues_panel.query = query

    assert_equal IssueStatus.all.sorted.where(:id => [1, 2]), issues_panel.panel_statuses
  end

  def test_issues
    issues_limit = 3
    issues_panel = Redmine::Helpers::IssuesPanel.new({:issues_limit => issues_limit})
    query = IssueQuery.new(:filters => { :status_id => {:operator => "*", :values => [""] } } )

    issues_panel.query = query
    assert_equal issues_limit, issues_panel.issues.count
  end
end
