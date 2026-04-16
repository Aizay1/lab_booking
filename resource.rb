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
    @time_based_bookings = []
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

  # Time-based booking methods
  def available_for_time_slot?(start_time, end_time)
    @time_based_bookings.none? { |booking| booking.overlaps?(start_time, end_time) }
  end

  def assign_time_based_booking(booking)
    @time_based_bookings << booking
  end

  def clear_time_based_booking(booking)
    @time_based_bookings.delete(booking)
  end

  def time_based_bookings
    @time_based_bookings.select(&:active?)
  end

  def all_time_based_bookings
    @time_based_bookings.dup
  end
end
