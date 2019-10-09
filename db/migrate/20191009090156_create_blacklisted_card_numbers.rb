class CreateBlacklistedCardNumbers < ActiveRecord::Migration[5.1]
  def change
    create_table :blacklisted_card_numbers do |t|
      t.string :card_number, null: false
    end
  end
end
