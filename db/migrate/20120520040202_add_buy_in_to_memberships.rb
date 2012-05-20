class AddBuyInToMemberships < ActiveRecord::Migration
  def change
    add_column :memberships, :buy_in, :integer, :default => 0
  end
end
