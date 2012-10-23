class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.string  :home_team
      t.string  :away_team
      t.decimal :spread
      t.decimal :over_under
      t.string  :game_time
      t.decimal :home_score
      t.decimal :away_score
      t.string  :game_id
      t.timestamps
    end
  end
end
