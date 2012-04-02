class UpdateGamesToGames < ActiveRecord::Migration
  def up
      add_column :games, :home_team, :string
      add_column :games, :away_team, :string
      add_column :games, :spread,    :double
      add_column :games, :over_under,:double
      add_column :games, :game_time, :DateTime
      add_column :games, :home_score,:double
      add_column :games, :away_score,:double
      add_column :games, :game_id,   :string
      
  end

  def down
  end
end
