require "test_helper"
class SaleItemTest < ActiveSupport::TestCase
  test "cantidad debe ser positiva" do
    # La validación se prueba sin persistir asociaciones.
    item = SaleItem.new(quantity: 0, unit_price: 1, subtotal: 0)
    assert_not item.valid?
    assert item.errors[:quantity].any?
  end
end
