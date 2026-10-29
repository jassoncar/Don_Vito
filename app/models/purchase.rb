class Purchase < ApplicationRecord
  belongs_to :supplier
  belongs_to :user
  has_many :purchase_items, dependent: :destroy
  enum :status, { draft: 0, received: 1, cancelled: 2 }, default: :draft
  validates :reference, presence: true, uniqueness: true
  def recalculate_total!
    update!(total: purchase_items.sum("quantity * unit_cost"))
  end
end
