class AddColsToMemberships < ActiveRecord::Migration
  def change
    add_column :memberships, :record, :string
    add_column :memberships, :buy_backs, :integer, :default => 0
  end
end
