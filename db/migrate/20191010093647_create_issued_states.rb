class CreateIssuedStates < ActiveRecord::Migration[5.1]
  def change
    create_table :issued_states do |t|
      t.string :pnr
      t.date :expiration_date

      t.timestamps
    end
  end
end
