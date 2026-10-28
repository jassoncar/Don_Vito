class SuppliersController < CrudController
  private

  def model_class = Supplier
  def permission_prefix = "suppliers"
  def title = "Proveedores"
  def singular = "Proveedor"
  def searchable = %w[name contact_name email phone tax_id]

  def columns
    [
      { key: "name", label: "Proveedor" },
      { key: "contact_name", label: "Contacto" },
      { key: "phone", label: "Teléfono" },
      { key: "email", label: "Correo" },
      { key: "is_active", label: "Estado", type: :bool }
    ]
  end

  def fields(_record = nil)
    {
      name: { label: "Nombre / Razón social", type: :text, col: 6 },
      tax_id: { label: "RUC / Identificación", type: :text, col: 6 },
      contact_name: { label: "Persona de contacto", type: :text, col: 6 },
      phone: { label: "Teléfono", type: :text, col: 6 },
      email: { label: "Correo electrónico", type: :email, col: 6 },
      address: { label: "Dirección", type: :text, col: 6 },
      is_active: { label: "Activo", type: :checkbox, default: true, col: 12 }
    }
  end

  def delete_error(record)
    "No se puede eliminar: el proveedor tiene compras registradas. Desactívelo en su lugar." if record.purchases.exists?
  end
end
