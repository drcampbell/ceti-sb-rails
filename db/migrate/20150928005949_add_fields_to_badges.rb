class AddFieldsToBadges < ActiveRecord::Migration
  def change
  	add_column :badges, :url, :string
  	add_column :badges, :file_name, :string
  	add_column :badges, :type, :string
  end
end
