class AddWinLossToBets < ActiveRecord::Migration
  def change
    add_column :bets, :won, :boolean, :default => nil   
  end
end
