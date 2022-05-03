class AddEmpiresBalanceSlackToGames < ActiveRecord::Migration[5.2]
  def change
    add_column :games, :empires_balance_slack, :integer, default: 0
  end
end
