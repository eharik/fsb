class AddBetTypeToBets < ActiveRecord::Migration
  def change
    add_column :bets, :bet_type, :string
  end
end
