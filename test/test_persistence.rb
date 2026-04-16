require "minitest/autorun"
require "tempfile"
require_relative "../persistence"
require_relative "../user"
require_relative "../resource"
require_relative "../booking_manager"
require_relative "../time_based_booking_manager"
require_relative "../constants"

class PersistenceTest < Minitest::Test
  def setup
    # Use a temporary file for testing
    @original_data_file = Persistence::DATA_FILE
    @temp_file = Tempfile.new(['lab_booking_test', '.json'])
    Persistence.remove_const(:DATA_FILE) if Persistence.const_defined?(:DATA_FILE)
    Persistence.const_set(:DATA_FILE, @temp_file.path)
    
    @users = [
      User.new(id: 1, name: "Test User", role: Roles::STUDENT),
      User.new(id: 2, name: "Test Assistant", role: Roles::ASSISTANT)
    ]
    
    @resources = [
      Resource.new(id: 1, name: "Test Resource", category: "test"),
      Resource.new(id: 2, name: "Another Resource", category: "equipment")
    ]
    
    @booking_manager = BookingManager.new
    @time_manager = TimeBasedBookingManager.new
  end

  def teardown
    @temp_file.close
    @temp_file.unlink
    Persistence.remove_const(:DATA_FILE) if Persistence.const_defined?(:DATA_FILE)
    Persistence.const_set(:DATA_FILE, @original_data_file)
  end

  def test_save_and_load_data
    # Create some bookings
    booking1 = @booking_manager.create_booking(user: @users[0], resource: @resources[0])
    booking2 = @booking_manager.create_booking(user: @users[1], resource: @resources[1])
    
    # Save data
    Persistence.save_data(
      users: @users,
      resources: @resources,
      booking_manager: @booking_manager,
      time_based_manager: @time_manager
    )
    
    # Load data
    loaded_data = Persistence.load_data
    
    assert_not_nil loaded_data
    assert_equal 2, loaded_data[:users].length
    assert_equal 2, loaded_data[:resources].length
    assert_equal 2, loaded_data[:booking_manager].all_bookings.length
    
    # Check user data
    loaded_user = loaded_data[:users].find { |u| u.id == 1 }
    assert_equal "Test User", loaded_user.name
    assert_equal Roles::STUDENT, loaded_user.role
    
    # Check resource data
    loaded_resource = loaded_data[:resources].find { |r| r.id == 1 }
    assert_equal "Test Resource", loaded_resource.name
    assert_equal "test", loaded_resource.category
  end

  def test_save_and_load_time_based_bookings
    # Create time-based bookings
    start_time = Time.now + 3600
    end_time = start_time + 3600
    
    booking1 = @time_manager.create_booking(
      user: @users[0],
      resource: @resources[0],
      start_time: start_time,
      end_time: end_time
    )
    
    booking2 = @time_manager.create_booking(
      user: @users[1],
      resource: @resources[1],
      start_time: start_time + 7200,
      end_time: end_time + 7200
    )
    
    # Save data
    Persistence.save_data(
      users: @users,
      resources: @resources,
      booking_manager: @booking_manager,
      time_based_manager: @time_manager
    )
    
    # Load data
    loaded_data = Persistence.load_data
    
    assert_not_nil loaded_data
    assert_equal 2, loaded_data[:time_based_manager].all_time_based_bookings.length
    
    # Check time-based booking data
    loaded_booking = loaded_data[:time_based_manager].all_time_based_bookings.first
    assert_equal @users[0].id, loaded_booking.user.id
    assert_equal @resources[0].id, loaded_booking.resource.id
    assert_equal start_time.strftime('%H:%M'), loaded_booking.start_time.strftime('%H:%M')
    assert_equal end_time.strftime('%H:%M'), loaded_booking.end_time.strftime('%H:%M')
  end

  def test_save_and_load_cancelled_bookings
    # Create and cancel a booking
    booking = @booking_manager.create_booking(user: @users[0], resource: @resources[0])
    booking.cancel
    
    # Save data
    Persistence.save_data(
      users: @users,
      resources: @resources,
      booking_manager: @booking_manager,
      time_based_manager: @time_manager
    )
    
    # Load data
    loaded_data = Persistence.load_data
    
    assert_not_nil loaded_data
    loaded_booking = loaded_data[:booking_manager].all_bookings.first
    assert_equal BookingStatuses::CANCELLED, loaded_booking.status
  end

  def test_data_exists_check
    assert_equal false, Persistence.data_exists?
    
    # Create a file
    File.write(Persistence::DATA_FILE, "{}")
    assert_equal true, Persistence.data_exists?
    
    # Clean up
    File.delete(Persistence::DATA_FILE)
  end

  def test_load_nonexistent_file
    result = Persistence.load_data
    assert_nil result
  end

  def test_backup_data
    # Create a data file first
    File.write(Persistence::DATA_FILE, '{"test": "data"}')
    
    # Test backup
    Persistence.backup_data
    
    # Check that backup file was created
    backup_files = Dir.glob("#{Persistence::DATA_FILE}.backup.*")
    assert_equal 1, backup_files.length
    
    # Clean up
    File.delete(Persistence::DATA_FILE)
    File.delete(backup_files.first)
  end

  def test_clear_data
    # Create a data file first
    File.write(Persistence::DATA_FILE, '{"test": "data"}')
    
    # Clear data
    Persistence.clear_data
    
    # Check that file is gone
    assert_equal false, File.exist?(Persistence::DATA_FILE)
  end

  def test_handle_corrupted_json_file
    # Create a corrupted JSON file
    File.write(Persistence::DATA_FILE, '{"invalid": json}')
    
    # Try to load
    result = Persistence.load_data
    assert_nil result
    
    # Clean up
    File.delete(Persistence::DATA_FILE)
  end

  def test_save_data_with_nil_time_based_manager
    # Create some bookings
    booking = @booking_manager.create_booking(user: @users[0], resource: @resources[0])
    
    # Save data without time-based manager
    Persistence.save_data(
      users: @users,
      resources: @resources,
      booking_manager: @booking_manager,
      time_based_manager: nil
    )
    
    # Load data
    loaded_data = Persistence.load_data
    
    assert_not_nil loaded_data
    assert_equal 1, loaded_data[:booking_manager].all_bookings.length
    assert_equal 0, loaded_data[:time_based_manager].all_time_based_bookings.length
  end
end
