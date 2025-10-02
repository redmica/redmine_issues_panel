require File.expand_path('../../test_helper', __FILE__)

class IssueCardPositionTest < ActiveSupport::TestCase
  def setup
    User.current = User.find(1)
  end

  def test_update_positions
    IssueCardPosition.delete_all
    assert_equal 0, IssueCardPosition.count

    # insert new positions
    IssueCardPosition.update_positions!([3, 1, 2])
    assert_equal 3, IssueCardPosition.count
    assert_equal 0, IssueCardPosition.find_by(issue_id: 3).position
    assert_equal 1, IssueCardPosition.find_by(issue_id: 1).position
    assert_equal 2, IssueCardPosition.find_by(issue_id: 2).position

    # update existing positions
    IssueCardPosition.update_positions!([2, 3, 1])
    assert_equal 3, IssueCardPosition.count
    assert_equal 0, IssueCardPosition.find_by(issue_id: 2).position
    assert_equal 1, IssueCardPosition.find_by(issue_id: 3).position
    assert_equal 2, IssueCardPosition.find_by(issue_id: 1).position

    # mixed existing and new positions
    IssueCardPosition.update_positions!([4, 1, 3, 5])
    assert_equal 5, IssueCardPosition.count
    assert_equal 0, IssueCardPosition.find_by(issue_id: 4).position
    assert_equal 1, IssueCardPosition.find_by(issue_id: 1).position
    assert_equal 2, IssueCardPosition.find_by(issue_id: 3).position
    assert_equal 3, IssueCardPosition.find_by(issue_id: 5).position
  end
end
