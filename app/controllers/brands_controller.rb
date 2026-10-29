class BrandsController < CrudController
  private

  def model_class = Brand
  def permission_prefix = "brands"
  def title = "Marcas"
  def singular = "Marca"

  def columns
    [
      { key: "name", label: "Nombre" },
      { key: "description", label: "Descripción" },
      { key: "is_active", label: "Estado", type: :bool }
    ]
  end

  def fields(_record = nil)
    {
      name: { label: "Nombre", type: :text, col: 6 },
      description: { label: "Descripción", type: :text, col: 6 },
      is_active: { label: "Activa", type: :checkbox, default: true, col: 12 }
    }
  end

  def delete_error(record)
    "No se puede eliminar: la marca tiene productos asociados." if record.products.exists?
  end
end
