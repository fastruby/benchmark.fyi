class AddAttributesToReports < ActiveRecord::Migration[7.0]
  def change
    add_column :reports, :ruby, :string
    add_column :reports, :os, :string
    add_column :reports, :arch, :string
  end
end
