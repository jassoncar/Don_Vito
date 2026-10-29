class PurchaseItem < ApplicationRecord
  belongs_to :purchase
  belongs_to :product
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_cost, numericality: { greater_than_or_equal_to: 0 }
end
