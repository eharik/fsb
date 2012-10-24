class AddTeamToBets < ActiveRecord::Migration
  def change
		add_column :bets, :team, :string
  end
end
