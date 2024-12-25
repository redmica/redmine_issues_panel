require File.expand_path('../../test_helper', __FILE__)

class IssueCardTest < ActiveSupport::TestCase
  def setup
    User.current = User.find(1)
  end

  def test_move_status
    issue_card = IssueCard.find(1)
    assert_equal 1, issue_card.status_id

    issue_card.move!({ :status_id => 2 })
    assert_equal 2, issue_card.status_id
  end

  def test_move_relation_group
    issue_card = IssueCard.find(1)

    assert_equal 1, issue_card.tracker_id
    issue_card.move!({ :group_key => 'tracker_id', :group_value => 2 })
    assert_equal 2, issue_card.tracker_id

    assert_equal 1, issue_card.project_id
    issue_card.move!({ :group_key => 'project_id', :group_value => 2 })
    assert_equal 2, issue_card.project_id

    assert_equal 4, issue_card.category_id
    issue_card.move!({ :group_key => 'category_id', :group_value => 3 })
    assert_equal 3, issue_card.category_id

    assert_nil issue_card.assigned_to_id
    issue_card.move!({ :group_key => 'assigned_to_id', :group_value => 2 })
    assert_equal 2, issue_card.assigned_to_id

    assert_equal 4, issue_card.priority_id
    issue_card.move!({ :group_key => 'priority_id', :group_value => 7 })
    assert_equal 7, issue_card.priority_id

    assert_nil issue_card.fixed_version_id
    issue_card.move!({ :group_key => 'fixed_version_id', :group_value => 5 })
    assert_equal 5, issue_card.fixed_version_id
  end

  def test_move_custom_field_group
    issue_card = IssueCard.find(1)
    field = IssueCustomField.find_by_name('Database')
    assert issue_card.available_custom_fields.include?(field)
    assert_nil issue_card.custom_field_value(field.id)

    issue_card.move!({ :group_key => 'custom_field_values', :group_value => '1,PostgreSQL'})
    assert_equal 'PostgreSQL', issue_card.custom_field_value(field.id)
  end

  def test_css_classes_include_icon_checked
    closed_issue_card = IssueCard.find(8)
    closed_classes = closed_issue_card.css_classes.split(' ')
    assert_include 'icon', closed_classes
    assert_include 'icon-checked', closed_classes

    issue_card = IssueCard.find(1)
    classes = issue_card.css_classes.split(' ')
    assert_not_include 'icon', classes
    assert_not_include 'icon-checked', classes
  end
end
