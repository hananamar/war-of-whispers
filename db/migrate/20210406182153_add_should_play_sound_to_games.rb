class AddShouldPlaySoundToGames < ActiveRecord::Migration[5.2]
  def change
    add_column :games, :should_play_audio, :boolean, default: true
  end
end
