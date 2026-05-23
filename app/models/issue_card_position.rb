class IssueCardPosition < ActiveRecord::Base
  class << self
    def update_positions!(ordered_issue_ids=[])
      return if ordered_issue_ids.blank?
      ordered_issue_positions = ordered_issue_ids.each_with_index.map { |id, i| { issue_id: id, position: i } }
      opts = { update_only: %i[position] }
      # :unique_by option is supported only by PostgreSQL and SQLite3
      opts[:unique_by] = 'index_issue_card_positions_on_issue_id' if Redmine::Database.postgresql? || Redmine::Database.sqlite?
      self.upsert_all(ordered_issue_positions, **opts)
    end
  end

  def to_s
    position.to_s
  end
end
