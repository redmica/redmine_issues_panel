require File.expand_path('../../test_helper', __FILE__)

class IssuesPanelControllerTest < ActionController::TestCase
  def setup
    @request.session[:user_id] = 2
  end

  def test_index_with_out_query
    get :index
    assert_response :success
    assert_query_form
  end

  def test_index_should_forbidden_if_module_disabled
    # Enabled Issues Panel
    @project = Project.find(1)
    @project.enabled_modules = [] #<< EnabledModule.new(name: 'issues_panel')
    @project.save!

    get :index, :params => {
      :project_id => 1
    }
    assert_response :forbidden
  end

  def test_index_with_issues_panel_query
    # Enabled Issues Panel
    @project = Project.find(1)
    @project.enabled_modules << EnabledModule.new(name: 'issues_panel')
    @project.save!

    get :index, :params => {
      :project_id => 1,
      :query_id => 100
    }
    assert_response :success

    # query form
    assert_query_form

    issue_ids_on_status_1 = [1, 3, 5, 6, 7, 9, 10, 13, 14]
    issue_ids_on_status_2 = [2]
    issue_ids_on_status_5 = [8, 11, 12]

    # issues panel
    assert_select 'table#issues_panel.issues-panel' do
      assert_select 'thead' do
        assert_select 'tr' do
          assert_select 'th', "New#{issue_ids_on_status_1.count}"
          assert_select 'th', "Assigned#{issue_ids_on_status_2.count}"
          assert_select 'th', "Closed#{issue_ids_on_status_5.count}"
        end
      end
      assert_select 'tr' do
        assert_select 'td.issue-card-receiver[data-status-id=1]' do
          assert_issue_cards(issue_ids_on_status_1)
        end
        assert_select 'td.issue-card-receiver[data-status-id=2]' do
          assert_issue_cards(issue_ids_on_status_2)
        end
        assert_select 'td.issue-card-receiver[data-status-id=5]' do
          assert_issue_cards(issue_ids_on_status_5)
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

  def test_move_issue_card
    put :move_issue_card, :xhr => true, :params => {
      :id => 1, :status_id => 5
    }
    assert_response :success
    assert_match "$('#issue-card-1').remove()", response.body
    assert_match "$('#issues-count-on-status-1').html('0')", response.body
    assert_match "$('#issues-count-on-status-5').html('4')", response.body
    assert_match "$('.issues-count-on-group').html('0');", response.body
    assert_match "$('#issues-count-on-group-').html('4');", response.body
    assert_match "loadDraggableSettings();", response.body
  end

  def test_move_issue_card_but_record_not_found
    put :move_issue_card, :xhr => true, :params => {
      :id => 99999, :status_id => 2
    }
    assert_response :success
    assert_match "alert('#{I18n.t(:error_issue_not_found_in_project)}')", response.body
    assert_match "('#issue-card-').animate( {left: 0, top: 0}, 500 );", response.body
  end

  def test_move_issue_card_but_unauthorized
    IssueCard.any_instance.stubs(:visible?).returns(false)
    put :move_issue_card, :xhr => true, :params => {
      :id => 1, :status_id => 2
    }
    assert_response :success
    assert_match "alert('#{I18n.t(:notice_not_authorized_to_change_this_issue)}')", response.body
    assert_match "('#issue-card-1').animate( {left: 0, top: 0}, 500 );", response.body
  end

  def test_move_issue_card_but_exception_raised
    error_message_on_move = 'error message on move'
    IssueCard.any_instance.stubs(:move!).raises(error_message_on_move)
    put :move_issue_card, :xhr => true, :params => {
      :id => 1, :status_id => 2
    }
    assert_response :success
    assert_match "alert('#{error_message_on_move}')", response.body
    assert_match "('#issue-card-1').animate( {left: 0, top: 0}, 500 );", response.body
  end

  def assert_modal_issue_card()
    assert_match "showModal('new-issue-card-modal', '450px');", response.body
    assert_match "$('#new-issue-card-modal').addClass('new-issue-card');", response.body
  end

  def test_new_issue_card
    get :new_issue_card, :xhr => true, :params => {
      :status_id => 5
    }
    assert_response :success
    assert_modal_issue_card
  end

  def test_new_issue_card_method_post
    post :new_issue_card, :xhr => true, :params => {
      :status_id => 5
    }
    assert_response :success
    assert_modal_issue_card
  end

  def test_show_description
    issue = Issue.generate!(:description => 'Issue Description', :author => User.current)
    get :show_issue_description, :xhr => true, :params => {
      :id => issue.id
    }
    assert_response :success
    assert_equal 'application/json', response.media_type
    data = ActiveSupport::JSON.decode(response.body)
    assert_select(Nokogiri::HTML(data['description']), "div.issue") do
      assert_select 'div.subject', "##{issue.id}: #{issue.subject}"
      assert_select 'div.description' do
        assert_select 'div.wiki', issue.description
      end
    end
  end

  def test_show_description_but_record_not_found
    put :show_issue_description, :xhr => true, :params => {
      :id => 99999
    }
    assert_response :success
    assert_equal 'application/json', response.media_type
    data = ActiveSupport::JSON.decode(response.body)
    assert_equal I18n.t(:error_issue_not_found_in_project), data['error_message']
  end

  def test_show_issue_description_but_unauthorized
    IssueCard.any_instance.stubs(:visible?).returns(false)
    put :show_issue_description, :xhr => true, :params => {
      :id => 1
    }

    assert_response :success
    assert_equal 'application/json', response.media_type
    data = ActiveSupport::JSON.decode(response.body)
    assert_equal I18n.t(:notice_not_authorized_to_change_this_issue), data['error_message']
  end

  def test_show_issue_description_when_description_is_nil
    issue = Issue.generate!(:description => nil, :author => User.current)
    get :show_issue_description, :xhr => true, :params => {
      :id => issue.id
    }
    assert_response :success
    assert_equal 'application/json', response.media_type
    data = ActiveSupport::JSON.decode(response.body)
    assert_select(Nokogiri::HTML(data['description']), "div.issue") do
      assert_select 'div.subject', "##{issue.id}: #{issue.subject}"
      assert_select 'div.description' do
        assert_select 'div.wiki', ''
      end
    end
  end
end
