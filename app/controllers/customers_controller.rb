class CustomersController < CrudController
  private

  def model_class = Customer
  def permission_prefix = "customers"
  def title = "Clientes"
  def singular = "Cliente"
  def searchable = %w[name email phone tax_id]

  def columns
    [
      { key: "name", label: "Cliente" },
      { key: "tax_id", label: "Identificación" },
      { key: "phone", label: "Teléfono" },
      { key: "email", label: "Correo" },
      { key: "is_active", label: "Estado", type: :bool }
    ]
  end

  def fields(_record = nil)
    {
      name: { label: "Nombre", type: :text, col: 6 },
      tax_id: { label: "Cédula / RUC", type: :text, col: 6 },
      phone: { label: "Teléfono", type: :text, col: 6 },
      email: { label: "Correo electrónico", type: :email, col: 6 },
      address: { label: "Dirección", type: :text, col: 12 },
      is_active: { label: "Activo", type: :checkbox, default: true, col: 12 }
    }
  end

  def delete_error(record)
    "No se puede eliminar: el cliente tiene ventas registradas. Desactívelo en su lugar." if record.sales.exists?
  end
end
