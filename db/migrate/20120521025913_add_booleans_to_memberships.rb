class AddBooleansToMemberships < ActiveRecord::Migration
  def change
    add_column :memberships, :activate_buy_in,   :boolean, :default => false
    add_column :memberships, :activate_buy_back, :boolean, :default => false
  end
end
