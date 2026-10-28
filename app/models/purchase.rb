class Purchase < ApplicationRecord
  include Auditable
  include Codeable

  STATUSES = { "ordered" => "Ordenada", "received" => "Recibida", "cancelled" => "Cancelada" }.freeze

  belongs_to :supplier
  belongs_to :user
  has_many :purchase_items, dependent: :destroy

  def status_label
    STATUSES[status] || status
  end
end
