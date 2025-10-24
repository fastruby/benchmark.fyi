class Report < ActiveRecord::Base
  ALPHABET = "123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ"
  BASE = ALPHABET.length
  REQUIRED_ENTRY_ATTRIBUTES = %W(name ips stddev microseconds iterations cycles)

  serialize :report, coder: JSON
  alias_attribute :entries, :report
  validates :entries, presence: true
  validate :validate_entries_attributes

  def short_id
    int_val = self.id

    base58_val = ''
    while int_val >= BASE
      mod = int_val % BASE
      base58_val = ALPHABET[mod,1] + base58_val
      int_val = (int_val - mod)/BASE
    end

    ALPHABET[int_val,1] + base58_val
  end

  def self.find_from_short_id(base58_val)
    int_val = 0
    base58_val.reverse.split(//).each_with_index do |char,index|
      raise ArgumentError, 'Value passed not a valid Base58 String.' if (char_index = ALPHABET.index(char)).nil?
      int_val += (char_index)*(BASE**(index))
    end

    Report.find int_val
  end

  private
  def validate_entries_attributes
    return if entries.blank?

    invalid_entries = entries.reject { |entry| valid_entry?(entry) }

    if invalid_entries.any?
      errors.add(:entries, "missing attributes: #{ invalid_entries.map { |entry| error_message(entry) }.join(", ")}")
    end
  end

  def valid_entry?(entry)
    REQUIRED_ENTRY_ATTRIBUTES.all? do |attr|
      entry[attr].present?
    end
  end

  def error_message(entry)
    missing_attributes = REQUIRED_ENTRY_ATTRIBUTES - entry.keys

    "#{entry} (#{missing_attributes.join(", ")})"
  end
end
