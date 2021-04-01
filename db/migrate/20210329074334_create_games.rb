class CreateGames < ActiveRecord::Migration[5.2]
  def change
    create_table :games do |t|
      # t.integer :players_count
      t.string :shuffle_method, default: Game::DEFAULT_METHOD
      t.integer :player_to_factions_array, array: true
      t.jsonb :player_loyalties_hash
      t.jsonb :player_end_ranking

      t.timestamps
    end
  end
end
