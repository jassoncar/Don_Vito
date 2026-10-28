class RolesController < ApplicationController
  before_action(only: :index) { require_permission!("roles.view") }
  before_action(only: %i[new create]) { require_permission!("roles.create") }
  before_action(only: %i[edit update]) { require_permission!("roles.edit") }
  before_action(only: :destroy) { require_permission!("roles.delete") }
  before_action :set_role, only: %i[edit update destroy]

  def index
    @roles = Role.includes(:permissions, :users).order(:name)
  end

  def new
    @role = Role.new
    @granted = []
  end

  def create
    @role = Role.new(name: params.dig(:role, :name).to_s.strip, description: params.dig(:role, :description).presence)
    @role.slug = unique_slug(@role.name)
    @granted = granted_names

    ok = false
    Role.transaction do
      ok = @role.save
      @role.permissions = Permission.where(name: @granted) if ok
    end

    if ok
      redirect_to roles_path, notice: "Rol creado correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @granted = @role.permissions.pluck(:name)
  end

  def update
    # El rol Administrador siempre tiene acceso total: solo se edita la descripción.
    if @role.admin?
      @role.update(description: params.dig(:role, :description).presence)
      return redirect_to roles_path, notice: "Rol actualizado correctamente."
    end

    @granted = granted_names
    @role.assign_attributes(name: params.dig(:role, :name).to_s.strip, description: params.dig(:role, :description).presence)

    ok = false
    Role.transaction do
      ok = @role.save
      @role.permissions = Permission.where(name: @granted) if ok
    end

    if ok
      redirect_to roles_path, notice: "Rol actualizado correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @role.admin?
      redirect_to roles_path, alert: "El rol Administrador no se puede eliminar."
    elsif @role.users.exists?
      redirect_to roles_path, alert: "No se puede eliminar: hay usuarios asignados a este rol."
    else
      @role.destroy!
      redirect_to roles_path, notice: "Rol eliminado correctamente."
    end
  end

  private

  def set_role
    @role = Role.find(params[:id])
  end

  def granted_names
    Array(params[:permissions]).map(&:to_s) & Permission.pluck(:name)
  end

  def unique_slug(name)
    base = name.parameterize.presence || "rol"
    slug = base
    i = 2
    while Role.exists?(slug: slug)
      slug = "#{base}-#{i}"
      i += 1
    end
    slug
  end
end
