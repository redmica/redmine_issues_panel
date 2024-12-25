require File.expand_path('../../test_helper', __FILE__)

class IssueQueryTest < ActiveSupport::TestCase
  def test_build_from_params_should_set_issues_num_per_row
    q = IssueQuery.create!(:name => 'issue panel', :options => {})

    q.build_from_params({ :issues_num_per_row => 2 })
    assert_equal 2, q.options[:issues_num_per_row]

    q.build_from_params({ :query => { :issues_num_per_row => 3 } })
    assert_equal 3, q.options[:issues_num_per_row]
  end

  def test_issues_num_per_row_should_set_options_value
    q = IssueQuery.create!(:name => 'issue panel', :options => {})
    q.issues_num_per_row = 2
    assert_equal 2, q.options[:issues_num_per_row]
  end

  def test_issues_num_per_row_should_return_default_value
    q = IssueQuery.create!(:name => 'issue panel', :options => {})
    assert_equal 1, q.issues_num_per_row
  end

  def test_issues_num_per_row_should_return_options_value
    q = IssueQuery.create!(:name => 'issue panel', :options => {:issues_num_per_row => 3})
    assert_equal 3, q.issues_num_per_row
  end
end
