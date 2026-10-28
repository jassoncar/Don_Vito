class CategoriesController < CrudController
  private

  def model_class = Category
  def permission_prefix = "categories"
  def title = "Categorías"
  def singular = "Categoría"

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
    "No se puede eliminar: la categoría tiene productos asociados." if record.products.exists?
  end
end
