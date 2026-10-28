# CRUD genérico basado en configuración. Cada módulo define columnas, campos y permisos.
class CrudController < ApplicationController
  ACTION_PERMISSIONS = {
    "index" => "view", "new" => "create", "create" => "create",
    "edit" => "edit", "update" => "edit", "destroy" => "delete"
  }.freeze

  before_action :set_record, only: %i[edit update destroy]
  before_action { require_permission!("#{permission_prefix}.#{ACTION_PERMISSIONS[action_name]}") }
  before_action :setup_view

  helper_method :form_fields

  def index
    scope = includes_list.present? ? model_class.includes(*includes_list) : model_class.all
    if params[:q].present?
      clause = searchable.map { |column| "#{model_class.table_name}.#{column} LIKE :q" }.join(" OR ")
      scope = scope.where(clause, q: "%#{model_class.sanitize_sql_like(params[:q].to_s.strip)}%")
    end
    @records = paginate(scope.order(default_order))
    render "crud/index"
  end

  def new
    @record = model_class.new
    form_fields.each do |name, field|
      @record.public_send("#{name}=", field[:default]) if field.key?(:default) && @record.respond_to?("#{name}=")
    end
    render "crud/form"
  end

  def create
    @record = model_class.new(record_params)
    return if before_save(@record) == false

    if @record.save
      redirect_to url_for(action: :index), notice: "#{@singular} creado correctamente."
    else
      render "crud/form", status: :unprocessable_entity
    end
  end

  def edit
    render "crud/form"
  end

  def update
    @record.assign_attributes(record_params)
    return if before_save(@record) == false

    if @record.save
      redirect_to url_for(action: :index), notice: "#{@singular} actualizado correctamente."
    else
      render "crud/form", status: :unprocessable_entity
    end
  end

  def destroy
    if (message = delete_error(@record))
      redirect_to url_for(action: :index), alert: message
      return
    end

    @record.destroy!
    redirect_to url_for(action: :index), notice: "#{@singular} eliminado correctamente."
  rescue ActiveRecord::InvalidForeignKey, ActiveRecord::DeleteRestrictionError
    redirect_to url_for(action: :index), alert: "No se puede eliminar: el registro está en uso."
  end

  private

  def set_record
    @record = model_class.find(params[:id])
  end

  def setup_view
    @title = title
    @singular = singular
    @columns = columns
    @permission = permission_prefix
    @extra_actions = extra_actions
  end

  def form_fields
    @form_fields ||= fields(@record&.persisted? ? @record : nil)
  end

  def record_params
    permitted = params.require(model_class.model_name.param_key).permit(*form_fields.keys.map(&:to_sym))
    filter_params(permitted)
  end

  # --- Puntos de extensión -------------------------------------------------
  def includes_list = []
  def extra_actions = []
  def searchable = %w[name]
  def default_order = { name: :asc }
  def filter_params(permitted) = permitted
  def delete_error(_record) = nil

  # Devuelve false si ya respondió (por ejemplo con 403).
  def before_save(_record) = true
end
