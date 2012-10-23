class AddLockToBets < ActiveRecord::Migration
  def change
    add_column :bets, :lock, :boolean
  end
end
