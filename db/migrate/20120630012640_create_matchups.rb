class CreateMatchups < ActiveRecord::Migration
  def change
    create_table :matchups do |t|
      t.integer :league_id
      t.integer :week
      t.integer :away_team_id
      t.integer :home_team_id
      t.integer :away_team_score
      t.integer :home_team_score
      t.boolean :final, :default => false
    end
  end
end
