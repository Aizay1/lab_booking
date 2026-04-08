require_relative "errors"
require_relative "booking"

class BookingManager
  def initialize
    @bookings = []
  end

  def create_booking(user:, resource:)
    booking = Booking.new(user: user, resource: resource)
    @bookings << booking
    booking
  end

  def active_bookings
    @bookings.select(&:active?)
  end

  def all_bookings
    @bookings.dup
  end

  def available_resources(resources)
    resources.select(&:available?)
  end
end
