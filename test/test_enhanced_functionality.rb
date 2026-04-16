require "minitest/autorun"
require_relative "../resource"
require_relative "../booking_manager"
require_relative "../time_based_booking_manager"
require_relative "../constants"

class EnhancedFunctionalityTest < Minitest::Test
  def setup
    @resource1 = Resource.new(id: 1, name: "Microscope", category: "lab")
    @resource2 = Resource.new(id: 2, name: "Projector", category: "equipment")
    @resource3 = Resource.new(id: 3, name: "Router", category: "network")
    @resources = [@resource1, @resource2, @resource3]
    
    @manager = BookingManager.new
    @time_manager = TimeBasedBookingManager.new
    
    @now = Time.now
    @future_start = @now + 3600
    @future_end = @now + 7200
  end

  def test_resource_search_by_category
    lab_resources = @resources.select { |r| r.category == "lab" }
    equipment_resources = @resources.select { |r| r.category == "equipment" }
    
    assert_equal 1, lab_resources.length
    assert_equal @resource1, lab_resources.first
    assert_equal 1, equipment_resources.length
    assert_equal @resource2, equipment_resources.first
  end

  def test_available_resources_filtering
    # Book one resource
    user = User.new(id: 1, name: "Test", role: Roles::STUDENT)
    booking = @manager.create_booking(user: user, resource: @resource1)
    
    available = @manager.available_resources(@resources)
    assert_equal 2, available.length
    assert_includes available, @resource2
    assert_includes available, @resource3
    refute_includes available, @resource1
  end

  def test_time_based_resource_availability
    user = User.new(id: 1, name: "Test", role: Roles::STUDENT)
    
    # Create time-based booking
    booking = @time_manager.create_booking(
      user: user,
      resource: @resource1,
      start_time: @future_start,
      end_time: @future_end
    )
    
    # Check availability for overlapping time
    overlapping_available = @time_manager.available_resources_for_time_slot(
      @resources, 
      @future_start + 1800, 
      @future_end + 1800
    )
    assert_equal 2, overlapping_available.length
    refute_includes overlapping_available, @resource1
    
    # Check availability for non-overlapping time
    non_overlapping_available = @time_manager.available_resources_for_time_slot(
      @resources,
      @future_end + 3600,
      @future_end + 7200
    )
    assert_equal 3, non_overlapping_available.length
    assert_includes non_overlapping_available, @resource1
  end

  def test_booking_manager_lists_available_resources
    user = User.new(id: 1, name: "Test", role: Roles::STUDENT)
    
    # Book one resource
    @manager.create_booking(user: user, resource: @resource1)
    
    available = @manager.available_resources(@resources)
    assert_equal 2, available.length
    
    # Cancel booking and check again
    booking = @manager.all_bookings.first
    booking.cancel
    
    available_after_cancel = @manager.available_resources(@resources)
    assert_equal 3, available_after_cancel.length
  end

  def test_time_based_booking_overlap_detection
    user1 = User.new(id: 1, name: "User1", role: Roles::STUDENT)
    user2 = User.new(id: 2, name: "User2", role: Roles::STUDENT)
    
    # First booking
    booking1 = @time_manager.create_booking(
      user: user1,
      resource: @resource1,
      start_time: @future_start,
      end_time: @future_end
    )
    
    # Try overlapping booking (should fail)
    assert_raises(BookingError) do
      @time_manager.create_booking(
        user: user2,
        resource: @resource1,
        start_time: @future_start + 1800,  # 30 minutes overlap
        end_time: @future_end + 1800
      )
    end
    
    # Non-overlapping booking should work
    booking2 = @time_manager.create_booking(
      user: user2,
      resource: @resource1,
      start_time: @future_end + 3600,
      end_time: @future_end + 7200
    )
    
    assert_equal 2, @time_manager.all_time_based_bookings.length
  end

  def test_resource_time_slot_availability_check
    user = User.new(id: 1, name: "Test", role: Roles::STUDENT)
    
    # Initially available
    assert @resource1.available_for_time_slot?(@future_start, @future_end)
    
    # Create booking
    booking = @time_manager.create_booking(
      user: user,
      resource: @resource1,
      start_time: @future_start,
      end_time: @future_end
    )
    
    # No longer available for that time slot
    assert_equal false, @resource1.available_for_time_slot?(@future_start, @future_end)
    
    # Still available for different time slot
    assert @resource1.available_for_time_slot?(@future_end + 3600, @future_end + 7200)
  end

  def test_multiple_resources_time_based_bookings
    user1 = User.new(id: 1, name: "User1", role: Roles::STUDENT)
    user2 = User.new(id: 2, name: "User2", role: Roles::STUDENT)
    
    # Book different resources for same time slot
    booking1 = @time_manager.create_booking(
      user: user1,
      resource: @resource1,
      start_time: @future_start,
      end_time: @future_end
    )
    
    booking2 = @time_manager.create_booking(
      user: user2,
      resource: @resource2,
      start_time: @future_start,
      end_time: @future_end
    )
    
    assert_equal 2, @time_manager.all_time_based_bookings.length
    
    # Both resources should be unavailable for that time slot
    available = @time_manager.available_resources_for_time_slot(@resources, @future_start, @future_end)
    assert_equal 1, available.length
    assert_equal @resource3, available.first
  end

  def test_booking_manager_integration_with_time_based
    user = User.new(id: 1, name: "Test", role: Roles::STUDENT)
    
    # Create regular booking
    regular_booking = @manager.create_booking(user: user, resource: @resource1)
    
    # Create time-based booking for different resource
    time_booking = @time_manager.create_booking(
      user: user,
      resource: @resource2,
      start_time: @future_start,
      end_time: @future_end
    )
    
    # Both managers should work independently
    assert_equal 1, @manager.all_bookings.length
    assert_equal 1, @time_manager.all_time_based_bookings.length
    
    # Resource availability should be correct for each system
    assert_equal false, @resource1.available?  # Regular booking
    assert @resource1.available_for_time_slot?(@future_start, @future_end)  # No time-based booking
    
    assert @resource2.available?  # No regular booking
    assert_equal false, @resource2.available_for_time_slot?(@future_start, @future_end)  # Time-based booking
  end

  def test_edge_case_zero_duration_booking
    user = User.new(id: 1, name: "Test", role: Roles::STUDENT)
    
    # Zero duration booking should fail
    assert_raises(BookingError) do
      @time_manager.create_booking(
        user: user,
        resource: @resource1,
        start_time: @future_start,
        end_time: @future_start
      )
    end
  end

  def test_edge_case_booking_at_exact_boundary
    user1 = User.new(id: 1, name: "User1", role: Roles::STUDENT)
    user2 = User.new(id: 2, name: "User2", role: Roles::STUDENT)
    
    # First booking
    booking1 = @time_manager.create_booking(
      user: user1,
      resource: @resource1,
      start_time: @future_start,
      end_time: @future_end
    )
    
    # Second booking starting exactly when first ends
    booking2 = @time_manager.create_booking(
      user: user2,
      resource: @resource1,
      start_time: @future_end,
      end_time: @future_end + 3600
    )
    
    assert_equal 2, @time_manager.all_time_based_bookings.length
  end

  def test_edge_case_very_short_booking
    user = User.new(id: 1, name: "Test", role: Roles::STUDENT)
    
    # Very short booking (15 minutes)
    short_end = @future_start + 900  # 15 minutes
    
    booking = @time_manager.create_booking(
      user: user,
      resource: @resource1,
      start_time: @future_start,
      end_time: short_end
    )
    
    assert_equal 0.25, booking.duration_hours
    assert_equal 1, @time_manager.all_time_based_bookings.length
  end
end
