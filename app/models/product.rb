class Product < ApplicationRecord
  include Auditable

  IMAGE_DIR = Rails.root.join("public", "uploads", "products").freeze
  MAX_IMAGE_SIZE = 2.megabytes

  attr_accessor :initial_stock # solo al crear: genera el movimiento de stock inicial
  attr_accessor :image_file    # archivo subido desde el formulario
  attr_accessor :remove_image  # "1" para quitar la imagen actual

  belongs_to :category
  belongs_to :brand, optional: true
  belongs_to :supplier, optional: true
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

  before_save :persist_image
  after_create :register_initial_stock
  after_destroy_commit :delete_image_file

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

  def image_url
    "/uploads/products/#{image}" if image.present?
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

  def persist_image
    if uploaded_image?
      extension = self.class.detect_image_extension(image_file)
      filename = "#{SecureRandom.hex(12)}.#{extension}"
      FileUtils.mkdir_p(IMAGE_DIR)
      File.binwrite(IMAGE_DIR.join(filename), image_file.read)
      previous = image_was
      self.image = filename
      remove_file(previous)
    elsif remove_image.to_s == "1" && image.present?
      remove_file(image)
      self.image = nil
    end
  end

  def delete_image_file
    remove_file(image)
  end

  def remove_file(filename)
    return if filename.blank?

    path = IMAGE_DIR.join(File.basename(filename))
    File.delete(path) if File.exist?(path)
  end

  def register_initial_stock
    qty = initial_stock.to_i
    StockService.move(self, qty, "initial", notes: "Stock inicial al crear el producto") if qty > 0
  end
end
