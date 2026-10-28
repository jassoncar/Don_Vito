class SaleReturn < ApplicationRecord
  include Auditable
  include Codeable

  belongs_to :sale
  belongs_to :user
  has_many :sale_return_items, dependent: :destroy
end
