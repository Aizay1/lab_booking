require_relative "errors"
require_relative "time_based_booking"
require_relative "resource"

class TimeBasedBookingManager
  def initialize
    @time_based_bookings = []
  end

  def create_booking(user:, resource:, start_time:, end_time:)
    booking = TimeBasedBooking.new(
      user: user,
      resource: resource,
      start_time: start_time,
      end_time: end_time
    )
    @time_based_bookings << booking
    booking
  end

  def active_time_based_bookings
    @time_based_bookings.select(&:active?)
  end

  def all_time_based_bookings
    @time_based_bookings.dup
  end

  def bookings_for_resource(resource)
    @time_based_bookings.select { |booking| booking.resource == resource }
  end

  def bookings_for_user(user)
    @time_based_bookings.select { |booking| booking.user == user }
  end

  def bookings_in_time_range(start_time, end_time)
    @time_based_bookings.select do |booking|
      booking.overlaps?(start_time, end_time)
    end
  end

  def available_resources_for_time_slot(resources, start_time, end_time)
    resources.select do |resource|
      resource.available_for_time_slot?(start_time, end_time)
    end
  end

  def cancel_booking(booking)
    booking.cancel
    @time_based_bookings.delete(booking) if booking.cancelled?
  end

  def find_booking_by_id(id)
    @time_based_bookings.find { |booking| booking.object_id == id }
  end

  def conflicts_for_time_slot(resource, start_time, end_time)
    bookings_for_resource(resource).select do |booking|
      booking.overlaps?(start_time, end_time)
    end
  end
end
