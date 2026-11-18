class Product < ApplicationRecord
  include Auditable

  MAX_IMAGE_SIZE = 2.megabytes
  IMAGE_TYPES = { "jpg" => "image/jpeg", "png" => "image/png", "webp" => "image/webp" }.freeze

  attr_accessor :initial_stock # solo al crear: genera el movimiento de stock inicial
  attr_accessor :image_file    # archivo subido desde el formulario
  attr_accessor :remove_image  # "1" para quitar la imagen actual

  belongs_to :category
  belongs_to :brand, optional: true
  belongs_to :supplier, optional: true
  has_one :product_image, dependent: :delete
  has_many :stock_movements, dependent: :delete_all
  has_many :sale_items
  has_many :purchase_items
  has_many :inventory_adjustments

  normalizes :barcode, with: ->(value) { value.presence }

  validates :sku, presence: true, length: { maximum: 50 }, uniqueness: true
  validates :barcode, uniqueness: true, allow_nil: true
  validates :name, presence: true, length: { maximum: 255 }
  validates :cost_price, :sale_price, numericality: { greater_than_or_equal_to: 0 }
  validates :tax_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :min_stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :initial_stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_blank: true
  validate :validate_image_file

  scope :active, -> { where(is_active: true) }
  scope :low_stock, -> { where("products.stock <= products.min_stock") }

  before_save :prepare_image
  after_save :store_image
  after_create :register_initial_stock

  # Detecta el tipo real por los primeros bytes (no confía en la extensión ni en el Content-Type).
  def self.detect_image_extension(io)
    head = io.read(12).to_s.b
    io.rewind
    return "jpg" if head.start_with?("\xFF\xD8\xFF".b)
    return "png" if head.start_with?("\x89PNG\r\n\x1A\n".b)
    return "webp" if head[0, 4] == "RIFF".b && head[8, 4] == "WEBP".b

    nil
  end

  def low_stock?
    stock <= min_stock
  end

  # La columna `image` guarda un token de versión; los bytes viven en la tabla product_images.
  def image_url
    "/product_images/#{id}?v=#{image}" if image.present?
  end

  private

  def uploaded_image?
    image_file.respond_to?(:read) && image_file.respond_to?(:size) && image_file.size.to_i.positive?
  end

  def validate_image_file
    return unless uploaded_image?

    if image_file.size > MAX_IMAGE_SIZE
      errors.add(:image_file, "es demasiado grande (máximo 2 MB)")
    elsif self.class.detect_image_extension(image_file).nil?
      errors.add(:image_file, "debe ser una imagen JPG, PNG o WEBP")
    end
  end

  def prepare_image
    if uploaded_image?
      extension = self.class.detect_image_extension(image_file)
      @pending_image = { content_type: IMAGE_TYPES.fetch(extension), data: image_file.read }
      self.image = SecureRandom.hex(8)
    elsif remove_image.to_s == "1" && image.present?
      @remove_stored_image = true
      self.image = nil
    end
  end

  def store_image
    if @pending_image
      record = ProductImage.find_or_initialize_by(product_id: id)
      record.update!(content_type: @pending_image[:content_type], data: @pending_image[:data])
      @pending_image = nil
    elsif @remove_stored_image
      ProductImage.where(product_id: id).delete_all
      @remove_stored_image = nil
    end
  end

  def register_initial_stock
    qty = initial_stock.to_i
    StockService.move(self, qty, "initial", notes: "Stock inicial al crear el producto") if qty > 0
  end
end
