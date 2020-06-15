require File.expand_path('../../test_helper', __FILE__)

class IssuesBoardControllerTest < ActionController::TestCase
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
    @request.session[:user_id] = 2
  end

  def test_index_with_out_query
    get :index
    assert_response :success
    assert_query_form
  end

  def test_index_should_forbidden_if_module_disabled
    # Enabled Issues Board
    @project = Project.find(1)
    @project.enabled_modules = [] #<< EnabledModule.new(name: 'issues_board')
    @project.save!

    get :index, :params => {
      :project_id => 1
    }
    assert_response :forbidden
  end

  def test_index_with_issues_board_query
    # Enabled Issues Board
    @project = Project.find(1)
    @project.enabled_modules << EnabledModule.new(name: 'issues_board')
    @project.save!

    get :index, :params => {
      :project_id => 1,
      :query_id => 100
    }
    assert_response :success

    # query form
    assert_query_form

    # issues board
    assert_select 'table#issues_board.issues-board' do
      assert_select 'thead' do
        assert_select 'tr' do
          assert_select 'th', 'New'
          assert_select 'th', 'Assigned'
          assert_select 'th', 'Closed'
        end
      end
      assert_select 'tr' do
        assert_select 'td.issue-card-receiver[data-status-id=1]' do
          assert_issue_cards([1, 3, 5, 6, 7, 9, 10, 13, 14])
        end
        assert_select 'td.issue-card-receiver[data-status-id=2]' do
          assert_issue_cards([2])
        end
        assert_select 'td.issue-card-receiver[data-status-id=5]' do
          assert_issue_cards([8, 11, 12])
        end
      end
    end
  end

  def assert_query_form
    # query form
    assert_select 'form#query_form' do
      assert_select 'div#query_form_with_buttons.hide-when-print' do
        assert_select 'div#query_form_content' do
          assert_select 'fieldset#filters.collapsible'
          assert_select 'fieldset#options'
        end
        assert_select 'p.buttons'
      end
    end
  end

  def assert_issue_cards(issue_ids=[])
    issue_ids.each do |issue_id|
      assert_select "div#issue-card-#{issue_id}.issue-card[data-issue-id=#{issue_id}]"
    end
  end

  def test_move_issue_card_and_close
    put :move_issue_card, :xhr => true, :params => {
      :id => 1, :status_id => 5
    }
    assert_response :success
    assert_match "$('#issue-1').addClass('closed');", response.body
    assert_match "$('#issue-1').find('a.issue').addClass('closed');", response.body
  end

  def test_move_issue_card_and_open
    put :move_issue_card, :xhr => true, :params => {
      :id => 1, :status_id => 3 
    }
    assert_response :success
    assert_match "$('#issue-1').removeClass('closed');", response.body
    assert_match "$('#issue-1').find('a.issue').removeClass('closed');", response.body
  end

  def test_move_issue_card_but_record_not_found
    put :move_issue_card, :xhr => true, :params => {
      :id => 99999, :status_id => 2
    }
    assert_response :success
    assert_match "alert('#{I18n.t(:error_issue_not_found_in_project)}')", response.body
    assert_match "('.issue-card-receiver').sortable('cancel');", response.body
  end

  def test_move_issue_card_but_unauthorized
    IssueCard.any_instance.stubs(:visible?).returns(false)
    put :move_issue_card, :xhr => true, :params => {
      :id => 1, :status_id => 2
    }
    assert_response :success
    assert_match "alert('#{I18n.t(:notice_not_authorized_to_change_this_issue)}')", response.body
    assert_match "('.issue-card-receiver').sortable('cancel');", response.body
  end

  def test_move_issue_card_but_exception_raised
    error_message_on_move = 'error message on move'
    IssueCard.any_instance.stubs(:move!).raises(error_message_on_move)
    put :move_issue_card, :xhr => true, :params => {
      :id => 1, :status_id => 2
    }
    assert_response :success
    assert_match "alert('#{error_message_on_move}')", response.body
    assert_match "('.issue-card-receiver').sortable('cancel');", response.body
  end
end
