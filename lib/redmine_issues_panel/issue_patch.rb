require 'issue'

module RedmineIssuesPanel
  module IssuePatch
    def self.included(base)
      base.class_eval do
        has_one :issue_card_position, dependent: :destroy, foreign_key: :issue_id
      end
    end
  end
end

Issue.include RedmineIssuesPanel::IssuePatch
