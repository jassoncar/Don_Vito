class InventoryMovement < ApplicationRecord
  belongs_to :product
  belongs_to :user
  enum :movement_type, { purchase_in: 0, sale_out: 1, adjustment_in: 2, adjustment_out: 3, return_in: 4 }
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :reference_type, presence: true
end
