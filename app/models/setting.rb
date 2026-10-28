class Setting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  def self.get(key, default = nil)
    Current.settings ||= pluck(:key, :value).to_h
    Current.settings[key.to_s].presence || default
  end

  def self.put(values)
    values.each do |key, value|
      find_or_initialize_by(key: key.to_s).update!(value: value)
    end
    Current.settings = nil
  end
end
