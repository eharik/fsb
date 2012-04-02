class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.string :home_team
      t.string :away_team
      t.double :spread
      t.double :over_under
      t.string :game_time
      t.double :home_score
      t.double :away_score
      t.string :game_id

      t.timestamps
    end
  end
end
