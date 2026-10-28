class SaleReturnItem < ApplicationRecord
  belongs_to :sale_return
  belongs_to :sale_item
  belongs_to :product
end
