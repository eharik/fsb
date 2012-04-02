class AddNameToLeagues < ActiveRecord::Migration
  def change
    add_column :leagues, :name, :string
    add_column :leagues, :encrypted_password, :string
    add_column :leagues, :manager, :integer
    add_column :leagues, :league_settings, :text
    
  end
end
