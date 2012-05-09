class AddColumnsToBets < ActiveRecord::Migration
  
  def change
    
    add_column :bets, :user_id,   :integer
    add_column :bets, :league_id, :integer
    add_column :bets, :game_id,   :integer
    add_column :bets, :parlay_id, :integer
    
    add_column :bets, :risk,      :decimal
    add_column :bets, :win,       :decimal

  end
  
end
