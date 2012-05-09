class AddGameStatusToGame < ActiveRecord::Migration
  def change
    add_column :games, :game_status, :text
  end
end
