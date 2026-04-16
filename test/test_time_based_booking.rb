require "minitest/autorun"
require_relative "../time_based_booking"
require_relative "../time_based_booking_manager"
require_relative "../user"
require_relative "../resource"
require_relative "../constants"
require_relative "../errors"

class TimeBasedBookingTest < Minitest::Test
  def setup
    @student = User.new(id: 1, name: "kaleb", role: Roles::STUDENT)
    @assistant = User.new(id: 2, name: "yosi", role: Roles::ASSISTANT)
    @instructor = User.new(id: 3, name: "Dr.besufikad", role: Roles::INSTRUCTOR)
    @resource = Resource.new(id: 1, name: "Microscope", category: "lab")
    @manager = TimeBasedBookingManager.new
    
    # Set up test times
    @now = Time.now
    @future_start = @now + 3600  # 1 hour from now
    @future_end = @now + 7200    # 2 hours from now
  end

  def test_time_based_booking_creation
    booking = TimeBasedBooking.new(
      user: @student,
      resource: @resource,
      start_time: @future_start,
      end_time: @future_end
    )
    
    assert_equal @student, booking.user
    assert_equal @resource, booking.resource
    assert_equal BookingStatuses::ACTIVE, booking.status
    assert_equal @future_start, booking.start_time
    assert_equal @future_end, booking.end_time
    assert_equal 1.0, booking.duration_hours
  end

  def test_time_based_booking_requires_valid_times
    assert_raises(ValidationError) do
      TimeBasedBooking.new(user: @student, resource: @resource, start_time: nil, end_time: @future_end)
    end
    
    assert_raises(ValidationError) do
      TimeBasedBooking.new(user: @student, resource: @resource, start_time: @future_start, end_time: nil)
    end
  end

  def test_end_time_must_be_after_start_time
    assert_raises(BookingError) do
      TimeBasedBooking.new(
        user: @student,
        resource: @resource,
        start_time: @future_end,
        end_time: @future_start
      )
    end
  end

  def test_cannot_book_in_the_past
    past_time = @now - 3600
    
    assert_raises(BookingError) do
      TimeBasedBooking.new(
        user: @student,
        resource: @resource,
        start_time: past_time,
        end_time: @now
      )
    end
  end

  def test_only_students_or_assistants_can_book_time_based
    assert_raises(BookingError) do
      TimeBasedBooking.new(
        user: @instructor,
        resource: @resource,
        start_time: @future_start,
        end_time: @future_end
      )
    end
  end

  def test_time_overlap_detection
    # First booking
    booking1 = TimeBasedBooking.new(
      user: @student,
      resource: @resource,
      start_time: @future_start,
      end_time: @future_end
    )
    
    # Overlapping booking (should fail)
    assert_raises(BookingError) do
      TimeBasedBooking.new(
        user: @assistant,
        resource: @resource,
        start_time: @future_start + 1800,  # 30 minutes after first starts
        end_time: @future_end + 1800       # Overlaps with first booking
      )
    end
  end

  def test_no_overlap_for_different_times
    # First booking
    booking1 = TimeBasedBooking.new(
      user: @student,
      resource: @resource,
      start_time: @future_start,
      end_time: @future_end
    )
    
    # Non-overlapping booking (should succeed)
    later_start = @future_end + 3600
    later_end = later_start + 3600
    
    booking2 = TimeBasedBooking.new(
      user: @assistant,
      resource: @resource,
      start_time: later_start,
      end_time: later_end
    )
    
    assert_equal BookingStatuses::ACTIVE, booking2.status
  end

  def test_cancel_time_based_booking
    booking = TimeBasedBooking.new(
      user: @student,
      resource: @resource,
      start_time: @future_start,
      end_time: @future_end
    )
    
    assert_equal BookingStatuses::ACTIVE, booking.status
    booking.cancel
    assert_equal BookingStatuses::CANCELLED, booking.status
  end

  def test_cannot_cancel_already_cancelled_booking
    booking = TimeBasedBooking.new(
      user: @student,
      resource: @resource,
      start_time: @future_start,
      end_time: @future_end
    )
    
    booking.cancel
    assert_raises(BookingError) do
      booking.cancel
    end
  end

  def test_current_time_detection
    # Booking that includes current time (use future times to avoid past booking error)
    future_start = @now + 900   # 15 minutes from now
    future_end = @now + 2700    # 45 minutes from now
    
    booking = TimeBasedBooking.new(
      user: @student,
      resource: @resource,
      start_time: future_start,
      end_time: future_end
    )
    
    # Mock current time check by manually setting the time range to include now
    booking.instance_variable_set(:@start_time, @now - 1800)
    booking.instance_variable_set(:@end_time, @now + 1800)
    
    assert booking.current_time?
  end

  def test_duration_calculation
    start_time = @future_start
    end_time = start_time + (2.5 * 3600)  # 2.5 hours later
    
    booking = TimeBasedBooking.new(
      user: @student,
      resource: @resource,
      start_time: start_time,
      end_time: end_time
    )
    
    assert_equal 2.5, booking.duration_hours
  end

  def test_time_based_booking_manager_create_booking
    booking = @manager.create_booking(
      user: @student,
      resource: @resource,
      start_time: @future_start,
      end_time: @future_end
    )
    
    assert_instance_of TimeBasedBooking, booking
    assert_equal 1, @manager.all_time_based_bookings.length
  end

  def test_time_based_booking_manager_active_bookings
    # Create a booking that spans the current time
    # Start slightly in the past and end in the future to ensure it's currently active
    current_time = Time.now
    active_booking = @manager.create_booking(
      user: @student,
      resource: @resource,
      start_time: current_time - 30,   # 30 seconds ago
      end_time: current_time + 30      # 30 seconds from now
    )
    
    cancelled_booking = @manager.create_booking(
      user: @assistant,
      resource: @resource,
      start_time: @future_start,
      end_time: @future_end
    )
    cancelled_booking.cancel
    
    assert_equal 1, @manager.active_time_based_bookings.length
    assert_equal active_booking, @manager.active_time_based_bookings.first
  end

  def test_bookings_for_resource
    booking1 = @manager.create_booking(
      user: @student,
      resource: @resource,
      start_time: @future_start,
      end_time: @future_end
    )
    
    resource2 = Resource.new(id: 2, name: "Projector", category: "equipment")
    booking2 = @manager.create_booking(
      user: @assistant,
      resource: resource2,
      start_time: @future_start + 7200,
      end_time: @future_end + 7200
    )
    
    resource_bookings = @manager.bookings_for_resource(@resource)
    assert_equal 1, resource_bookings.length
    assert_equal booking1, resource_bookings.first
  end

  def test_bookings_for_user
    booking1 = @manager.create_booking(
      user: @student,
      resource: @resource,
      start_time: @future_start,
      end_time: @future_end
    )
    
    booking2 = @manager.create_booking(
      user: @student,
      resource: @resource,
      start_time: @future_start + 7200,
      end_time: @future_end + 7200
    )
    
    user_bookings = @manager.bookings_for_user(@student)
    assert_equal 2, user_bookings.length
    assert_includes user_bookings, booking1
    assert_includes user_bookings, booking2
  end

  def test_available_resources_for_time_slot
    resource2 = Resource.new(id: 2, name: "Projector", category: "equipment")
    resources = [@resource, resource2]
    
    # Book first resource
    @manager.create_booking(
      user: @student,
      resource: @resource,
      start_time: @future_start,
      end_time: @future_end
    )
    
    available = @manager.available_resources_for_time_slot(resources, @future_start, @future_end)
    assert_equal 1, available.length
    assert_equal resource2, available.first
  end

  def test_to_string_format
    booking = TimeBasedBooking.new(
      user: @student,
      resource: @resource,
      start_time: @future_start,
      end_time: @future_end
    )
    
    expected = "#{@student.name} -> #{@resource.name} (#{@future_start.strftime('%Y-%m-%d %H:%M')} - #{@future_end.strftime('%H:%M')})"
    assert_equal expected, booking.to_s
  end
end
