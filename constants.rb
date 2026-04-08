module Roles
  STUDENT = "student"
  ASSISTANT = "assistant"
  INSTRUCTOR = "instructor"

  BOOKING_ALLOWED = [STUDENT, ASSISTANT].freeze
end

module BookingStatuses
  ACTIVE = "active"
  CANCELLED = "cancelled"
end
