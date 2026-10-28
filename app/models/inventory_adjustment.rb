class InventoryAdjustment < ApplicationRecord
  include Auditable
  include Codeable

  REASONS = ["Conteo físico", "Merma", "Rotura", "Vencimiento", "Obsequio / muestra", "Otro"].freeze

  belongs_to :product
  belongs_to :user
end
