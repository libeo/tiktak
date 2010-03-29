class StxCitCompanies < ActiveRecord::Migration
  def self.up
    create_table :companies_cit_stx do |t|
      t.integer :company_id
      t.integer :rid_stx_company
    end
  end

  def self.down
    drop_table :companies_cit_stx
  end
end
