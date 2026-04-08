require "minitest/autorun"

require_relative "../user"
require_relative "../resource"
require_relative "../booking"
require_relative "../booking_manager"
require_relative "../errors"
require_relative "../constants"

class BookingTest < Minitest::Test
  def setup
    @student = User.new(id: 1, name: "kaleb", role: Roles::STUDENT)
    @assistant = User.new(id: 2, name: "yosi", role: Roles::ASSISTANT)
    @instructor = User.new(id: 3, name: "Dr.besufikad", role: Roles::INSTRUCTOR)
    @resource = Resource.new(id: 1, name: "Microscope", category: "lab")
  end

  def test_booking_an_available_resource_creates_active_booking
    booking = Booking.new(user: @student, resource: @resource)
    assert_equal BookingStatuses::ACTIVE, booking.status
    assert_equal false, @resource.available?
    assert_instance_of Time, booking.created_at
  end

  def test_booking_an_unavailable_resource_raises_error
    Booking.new(user: @student, resource: @resource)
    assert_raises(BookingError) do
      Booking.new(user: @assistant, resource: @resource)
    end
  end

  def test_cancelling_a_booking_changes_its_status
    booking = Booking.new(user: @student, resource: @resource)
    booking.cancel
    assert_equal BookingStatuses::CANCELLED, booking.status
  end

  def test_cancelling_a_booking_makes_the_resource_available_again
    booking = Booking.new(user: @student, resource: @resource)
    booking.cancel
    assert_equal true, @resource.available?
  end

  def test_only_students_or_assistants_can_book
    assert_raises(BookingError) do
      Booking.new(user: @instructor, resource: @resource)
    end
  end

  def test_booking_manager_lists_active_bookings
    manager = BookingManager.new
    b1 = manager.create_booking(user: @student, resource: @resource)
    assert_equal [b1], manager.active_bookings
    b1.cancel
    assert_equal [], manager.active_bookings
  end
end

