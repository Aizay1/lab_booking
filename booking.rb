require_relative "errors"
require_relative "constants"
require_relative "user"
require_relative "resource"

class Booking
  attr_reader :user, :resource, :status, :created_at

  def initialize(user:, resource:)
    raise ValidationError, "User is required" if user.nil?
    raise ValidationError, "Resource is required" if resource.nil?
    raise BookingError, "Only students or assistants can create bookings" unless user.can_book?
    raise BookingError, "Resource is already booked" unless resource.available?

    @user = user
    @resource = resource
    @status = BookingStatuses::ACTIVE
    @created_at = Time.now

    resource.assign_booking(self)
  end

  def cancel
    raise BookingError, "Booking is already cancelled" if cancelled?

    @status = BookingStatuses::CANCELLED
    resource.clear_booking
    self
  end

  def active?
    status == BookingStatuses::ACTIVE
  end

  def cancelled?
    status == BookingStatuses::CANCELLED
  end
end
