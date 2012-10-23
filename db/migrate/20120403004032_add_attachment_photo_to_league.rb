class AddAttachmentPhotoToLeague < ActiveRecord::Migration
  def self.up
    add_column :leagues, :photo_file_name, :string
    add_column :leagues, :photo_content_type, :string
    add_column :leagues, :photo_file_size, :integer
    add_column :leagues, :photo_updated_at, :datetime
  end

  def self.down
    remove_column :leagues, :photo_file_name
    remove_column :leagues, :photo_content_type
    remove_column :leagues, :photo_file_size
    remove_column :leagues, :photo_updated_at
  end
end
