class AddBetValueToBets < ActiveRecord::Migration
  def change
        add_column :bets, :bet_value, :float
  end
end
