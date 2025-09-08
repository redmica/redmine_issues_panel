class CreateIssueCardPositions < ActiveRecord::Migration[7.2]
  def change
    create_table :issue_card_positions do |t|
      t.column :issue_id, :integer, null: false
      t.column :position, :integer, null: false, default: 0
      t.column :created_on, :datetime, null: false
      t.column :updated_on, :datetime, null: false
    end
    add_index :issue_card_positions, :issue_id, name: 'index_issue_card_positions_on_issue_id', unique: true
  end
end
