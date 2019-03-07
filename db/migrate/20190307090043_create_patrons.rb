class CreatePatrons < ActiveRecord::Migration[5.1]
  def change
    create_table :patrons do |t|
      t.text :firstname
      t.text :surname
      t.text :care_of
      t.text :street
      t.text :zip
      t.text :city
      t.text :country
      t.text :phone
      t.text :email
      t.text :b_care_of
      t.text :b_street
      t.text :b_zip
      t.text :b_city
      t.text :b_country
      t.text :categorycode
      t.text :account
      t.text :pnr
      t.text :pnr12

      t.timestamps
    end
  end
end
