class StockService
  class Error < StandardError; end

  # Registra un movimiento de inventario y actualiza el stock del producto.
  # Debe ejecutarse dentro de una transacción (bloquea la fila del producto).
  # quantity: con signo (+ entrada, - salida)
  def self.move(product, quantity, kind, reference = nil, notes: nil)
    locked = Product.lock.find(product.id)
    new_stock = locked.stock + quantity.to_i

    if new_stock < 0
      raise Error, "Stock insuficiente para «#{locked.name}» (disponible: #{locked.stock})."
    end

    # update_all: no dispara auditoría por cada movimiento.
    Product.where(id: locked.id).update_all(stock: new_stock)
    product.stock = new_stock
    product.clear_attribute_changes(%w[stock])

    StockMovement.create!(
      product_id: locked.id,
      user_id: Current.user&.id,
      kind: kind,
      quantity: quantity.to_i,
      stock_after: new_stock,
      reference_type: reference&.class&.name,
      reference_id: reference&.id,
      notes: notes
    )
  end
end
