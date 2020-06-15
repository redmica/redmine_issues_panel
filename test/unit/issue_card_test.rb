require File.expand_path('../../test_helper', __FILE__)

class IssueCardTest < ActiveSupport::TestCase
  fixtures :projects, :users, :email_addresses, :user_preferences, :members, :member_roles, :roles,
           :groups_users,
           :trackers, :projects_trackers,
           :enabled_modules,
           :versions,
           :issue_statuses, :issue_categories, :issue_relations, :workflows,
           :enumerations,
           :issues, :journals, :journal_details,
           :watchers,
           :custom_fields, :custom_fields_projects, :custom_fields_trackers, :custom_values

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
    issue_card.move!({ :group_key => 'category_id', :group_value => 2 })
    assert_equal 2, issue_card.category_id

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
end
