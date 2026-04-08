class LabBookingError < StandardError; end

class ValidationError < LabBookingError; end
class BookingError < LabBookingError; end
