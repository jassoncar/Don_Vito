class SaleItem < ApplicationRecord
  belongs_to :sale
  belongs_to :product

  def returnable
    [quantity - returned_qty, 0].max
  end
end
