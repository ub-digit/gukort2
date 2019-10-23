class AddIndexToPnr < ActiveRecord::Migration[5.1]
  def change
    add_index :issued_states, :pnr, :unique => true
  end
end
