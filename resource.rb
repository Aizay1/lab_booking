require_relative "errors"

class Resource
  attr_reader :id, :name, :category

  def initialize(id:, name:, category:)
    raise ValidationError, "Resource id is required" if id.nil?
    raise ValidationError, "Resource name is required" if name.nil? || name.strip.empty?
    raise ValidationError, "Resource category is required" if category.nil? || category.strip.empty?

    @id = id
    @name = name
    @category = category
    @current_booking = nil
  end

  def available?
    @current_booking.nil? || @current_booking.cancelled?
  end

  def assign_booking(booking)
    @current_booking = booking
  end

  def clear_booking
    @current_booking = nil
  end

  def current_booking
    @current_booking
  end
end
