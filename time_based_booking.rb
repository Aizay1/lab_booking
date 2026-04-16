require_relative "errors"
require_relative "constants"
require_relative "user"
require_relative "resource"

class TimeBasedBooking
  attr_reader :user, :resource, :status, :created_at, :start_time, :end_time

  def initialize(user:, resource:, start_time:, end_time:)
    raise ValidationError, "User is required" if user.nil?
    raise ValidationError, "Resource is required" if resource.nil?
    raise ValidationError, "Start time is required" if start_time.nil?
    raise ValidationError, "End time is required" if end_time.nil?
    raise BookingError, "Only students or assistants can create bookings" unless user.can_book?
    raise BookingError, "End time must be after start time" if end_time <= start_time
    raise BookingError, "Cannot book in the past" if start_time < Time.now

    @user = user
    @resource = resource
    @start_time = start_time
    @end_time = end_time
    @status = BookingStatuses::ACTIVE
    @created_at = Time.now

    # Check for time conflicts before assigning
    unless resource.available_for_time_slot?(start_time, end_time)
      raise BookingError, "Resource is already booked during this time period"
    end

    resource.assign_time_based_booking(self)
  end

  def cancel
    raise BookingError, "Booking is already cancelled" if cancelled?

    @status = BookingStatuses::CANCELLED
    resource.clear_time_based_booking(self)
    self
  end

  def active?
    status == BookingStatuses::ACTIVE && current_time?
  end

  def cancelled?
    status == BookingStatuses::CANCELLED
  end

  def overlaps?(other_start, other_end)
    return false if cancelled?
    start_time < other_end && end_time > other_start
  end

  def current_time?
    Time.now >= start_time && Time.now <= end_time
  end

  def duration_hours
    ((end_time - start_time) / 3600).round(2)
  end

  def to_s
    "#{user.name} -> #{resource.name} (#{start_time.strftime('%Y-%m-%d %H:%M')} - #{end_time.strftime('%H:%M')})"
  end
end
