class AddResponseToMessages < ActiveRecord::Migration[5.1]
  def change
    add_column :messages, :response, :text
  end
end
