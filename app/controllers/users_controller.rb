class UsersController < CrudController
  private

  def model_class = User
  def permission_prefix = "users"
  def title = "Usuarios"
  def singular = "Usuario"
  def includes_list = %i[role]
  def searchable = %w[name email]

  def columns
    [
      { key: "name", label: "Nombre" },
      { key: "email", label: "Correo" },
      { key: "role.name", label: "Rol" },
      { key: "is_active", label: "Estado", type: :bool }
    ]
  end

  def fields(record = nil)
    roles = Role.order(:name)
    roles = roles.where.not(slug: "admin") unless current_user.admin?

    {
      name: { label: "Nombre completo", type: :text, col: 6 },
      email: { label: "Correo electrónico", type: :email, col: 6 },
      role_id: { label: "Rol", type: :select, col: 6, placeholder: "Seleccione...", options: roles.pluck(:name, :id) },
      password: { label: record ? "Nueva contraseña (dejar vacío para no cambiarla)" : "Contraseña", type: :password, col: 6 },
      is_active: { label: "Activo", type: :checkbox, default: true, col: 12 }
    }
  end

  def filter_params(permitted)
    permitted.delete(:password) if permitted[:password].blank?
    permitted
  end

  # Solo un administrador puede asignar el rol Administrador o editar administradores.
  def before_save(record)
    was_admin = record.persisted? && Role.find_by(id: record.role_id_was)&.admin?
    if (record.role&.admin? || was_admin) && !current_user.admin?
      render "shared/forbidden", status: :forbidden
      return false
    end

    record.is_active = true if record.id == current_user.id # no puede desactivarse a sí mismo
    true
  end

  def delete_error(record)
    return "No puede eliminar su propio usuario." if record.id == current_user.id
    return "Solo un administrador puede eliminar a otro administrador." if record.admin? && !current_user.admin?
    if record.admin? && User.joins(:role).where(roles: { slug: "admin" }).count <= 1
      return "No se puede eliminar al único administrador."
    end

    "No se puede eliminar: el usuario tiene movimientos registrados. Desactívelo en su lugar." if user_has_records?(record)
  end

  def user_has_records?(user)
    Sale.exists?(user_id: user.id) || Purchase.exists?(user_id: user.id) ||
      SaleReturn.exists?(user_id: user.id) || InventoryAdjustment.exists?(user_id: user.id)
  end
end
