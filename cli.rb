require 'date'
require 'time'
require_relative "user"
require_relative "resource"
require_relative "booking_manager"
require_relative "time_based_booking_manager"
require_relative "persistence"
require_relative "errors"
require_relative "constants"

class CLI
  def initialize
    @manager = BookingManager.new
    @time_manager = TimeBasedBookingManager.new
    @users = []
    @resources = []
    load_or_setup_data
  end

  def start
    puts "=== Lab Booking System ==="
    puts "Welcome to the Lab Resource Booking System!"
    
    loop do
      show_menu
      choice = get_user_input("Enter your choice (1-13): ").to_i
      
      case choice
      when 1
        list_resources
      when 2
        list_available_resources
      when 3
        search_resources_by_category
      when 4
        book_resource
      when 5
        cancel_booking
      when 6
        list_active_bookings
      when 7
        list_all_bookings
      when 8
        book_resource_with_time
      when 9
        list_time_based_bookings
      when 10
        cancel_time_based_booking
      when 11
        save_data
      when 12
        load_data
      when 13
        puts "Thank you for using the Lab Booking System. Goodbye!"
        break
      else
        puts "Invalid choice. Please try again."
      end
      
      puts "\nPress Enter to continue..."
      gets
    end
  end

  private

  def load_or_setup_data
    if Persistence.data_exists?
      puts "Loading saved data..."
      data = Persistence.load_data
      if data
        @users = data[:users]
        @resources = data[:resources]
        @manager = data[:booking_manager]
        @time_manager = data[:time_based_manager]
        puts "Data loaded successfully!"
      else
        puts "Failed to load data, using defaults"
        setup_sample_data
      end
    else
      puts "No saved data found, using defaults"
      setup_sample_data
    end
  end

  def setup_sample_data
    @users = [
      User.new(id: 1, name: "Hana", role: Roles::STUDENT),
      User.new(id: 2, name: "Nati", role: Roles::ASSISTANT),
      User.new(id: 3, name: "Dr. Besufikad", role: Roles::INSTRUCTOR),
      User.new(id: 4, name: "Kaleb", role: Roles::STUDENT)
    ]

    @resources = [
      Resource.new(id: 1, name: "Projector", category: "equipment"),
      Resource.new(id: 2, name: "Microscope", category: "lab"),
      Resource.new(id: 3, name: "Laptop", category: "equipment"),
      Resource.new(id: 4, name: "Router Kit", category: "network"),
      Resource.new(id: 5, name: "Centrifuge", category: "lab")
    ]
  end

  def show_menu
    system('clear') rescue system('cls')
    puts "\n=== Lab Booking System Menu ==="
    puts "1. List all resources"
    puts "2. List available resources"
    puts "3. Search resources by category"
    puts "4. Book a resource (simple)"
    puts "5. Cancel a booking"
    puts "6. List active bookings"
    puts "7. List all bookings"
    puts "--- Time-based Booking ---"
    puts "8. Book a resource with time slot"
    puts "9. List time-based bookings"
    puts "10. Cancel time-based booking"
    puts "--- Data Management ---"
    puts "11. Save data to file"
    puts "12. Load data from file"
    puts "13. Exit"
    puts "=================================="
  end

  def list_resources
    puts "\n--- All Resources ---"
    @resources.each_with_index do |resource, index|
      status = resource.available? ? "Available" : "Booked"
      puts "#{index + 1}. #{resource.name} (#{resource.category}) - #{status}"
    end
  end

  def list_available_resources
    puts "\n--- Available Resources ---"
    available = @manager.available_resources(@resources)
    if available.empty?
      puts "No resources are currently available."
    else
      available.each_with_index do |resource, index|
        puts "#{index + 1}. #{resource.name} (#{resource.category})"
      end
    end
  end

  def search_resources_by_category
    category = get_user_input("Enter category to search: ").strip
    puts "\n--- Resources in '#{category}' category ---"
    
    filtered = @resources.select { |r| r.category.downcase == category.downcase }
    if filtered.empty?
      puts "No resources found in '#{category}' category."
    else
      filtered.each_with_index do |resource, index|
        status = resource.available? ? "Available" : "Booked"
        puts "#{index + 1}. #{resource.name} - #{status}"
      end
    end
  end

  def book_resource
    puts "\n--- Book a Resource ---"
    
    # Show available users who can book
    puts "Available Users:"
    eligible_users = @users.select(&:can_book?)
    eligible_users.each_with_index do |user, index|
      puts "#{index + 1}. #{user.name} (#{user.role})"
    end
    
    user_choice = get_user_input("Select user (number): ").to_i - 1
    return unless valid_choice?(user_choice, eligible_users)
    
    selected_user = eligible_users[user_choice]
    
    # Show available resources
    puts "\nAvailable Resources:"
    available_resources = @manager.available_resources(@resources)
    if available_resources.empty?
      puts "No resources are currently available for booking."
      return
    end
    
    available_resources.each_with_index do |resource, index|
      puts "#{index + 1}. #{resource.name} (#{resource.category})"
    end
    
    resource_choice = get_user_input("Select resource (number): ").to_i - 1
    return unless valid_choice?(resource_choice, available_resources)
    
    selected_resource = available_resources[resource_choice]
    
    # Create booking
    begin
      booking = @manager.create_booking(user: selected_user, resource: selected_resource)
      puts "Successfully booked '#{selected_resource.name}' for #{selected_user.name}!"
      puts "Booking ID: #{booking.object_id} (for reference)"
    rescue BookingError => e
      puts "Booking failed: #{e.message}"
    end
  end

  def cancel_booking
    puts "\n--- Cancel a Booking ---"
    
    active_bookings = @manager.active_bookings
    if active_bookings.empty?
      puts "No active bookings to cancel."
      return
    end
    
    puts "Active Bookings:"
    active_bookings.each_with_index do |booking, index|
      puts "#{index + 1}. #{booking.user.name} -> #{booking.resource.name} (ID: #{booking.object_id})"
    end
    
    choice = get_user_input("Select booking to cancel (number): ").to_i - 1
    return unless valid_choice?(choice, active_bookings)
    
    selected_booking = active_bookings[choice]
    
    begin
      selected_booking.cancel
      puts "Successfully cancelled booking for '#{selected_booking.resource.name}'"
    rescue BookingError => e
      puts "Cancellation failed: #{e.message}"
    end
  end

  def list_active_bookings
    puts "\n--- Active Bookings ---"
    active_bookings = @manager.active_bookings
    
    if active_bookings.empty?
      puts "No active bookings."
    else
      active_bookings.each_with_index do |booking, index|
        puts "#{index + 1}. #{booking.user.name} (#{booking.user.role}) -> #{booking.resource.name} (#{booking.resource.category})"
        puts "   Created: #{booking.created_at.strftime('%Y-%m-%d %H:%M:%S')}"
        puts "   Status: #{booking.status}"
        puts
      end
    end
  end

  def list_all_bookings
    puts "\n--- All Bookings ---"
    all_bookings = @manager.all_bookings
    
    if all_bookings.empty?
      puts "No bookings found."
    else
      all_bookings.each_with_index do |booking, index|
        puts "#{index + 1}. #{booking.user.name} -> #{booking.resource.name}"
        puts "   Status: #{booking.status}"
        puts "   Created: #{booking.created_at.strftime('%Y-%m-%d %H:%M:%S')}"
        puts
      end
    end
  end

  def get_user_input(prompt)
    print prompt
    gets.chomp
  end

  def valid_choice?(choice, array)
    if choice >= 0 && choice < array.length
      true
    else
      puts "Invalid selection."
      false
    end
  end

  def book_resource_with_time
    puts "\n--- Book a Resource with Time Slot ---"
    
    # Show available users who can book
    puts "Available Users:"
    eligible_users = @users.select(&:can_book?)
    eligible_users.each_with_index do |user, index|
      puts "#{index + 1}. #{user.name} (#{user.role})"
    end
    
    user_choice = get_user_input("Select user (number): ").to_i - 1
    return unless valid_choice?(user_choice, eligible_users)
    
    selected_user = eligible_users[user_choice]
    
    # Show all resources
    puts "\nAll Resources:"
    @resources.each_with_index do |resource, index|
      puts "#{index + 1}. #{resource.name} (#{resource.category})"
    end
    
    resource_choice = get_user_input("Select resource (number): ").to_i - 1
    return unless valid_choice?(resource_choice, @resources)
    
    selected_resource = @resources[resource_choice]
    
    # Get time input
    puts "\nEnter booking time (24-hour format):"
    date_str = get_user_input("Date (YYYY-MM-DD, default today): ")
    time_str = get_user_input("Start time (HH:MM): ")
    duration = get_user_input("Duration in hours (default 2): ").to_f
    
    # Parse time
    date = date_str.empty? ? Date.today : Date.parse(date_str)
    start_time = Time.parse("#{date} #{time_str}")
    end_time = start_time + (duration * 3600)
    
    # Create time-based booking
    begin
      booking = @time_manager.create_booking(
        user: selected_user,
        resource: selected_resource,
        start_time: start_time,
        end_time: end_time
      )
      puts "Successfully booked '#{selected_resource.name}' for #{selected_user.name}!"
      puts "Time: #{booking.start_time.strftime('%Y-%m-%d %H:%M')} - #{booking.end_time.strftime('%H:%M')}"
      puts "Duration: #{booking.duration_hours} hours"
    rescue BookingError => e
      puts "Booking failed: #{e.message}"
    rescue => e
      puts "Invalid time format: #{e.message}"
    end
  end

  def list_time_based_bookings
    puts "\n--- Time-based Bookings ---"
    bookings = @time_manager.all_time_based_bookings
    
    if bookings.empty?
      puts "No time-based bookings found."
    else
      bookings.each_with_index do |booking, index|
        status = booking.current_time? ? "ACTIVE NOW" : "Scheduled"
        puts "#{index + 1}. #{booking.user.name} -> #{booking.resource.name}"
        puts "   Time: #{booking.start_time.strftime('%Y-%m-%d %H:%M')} - #{booking.end_time.strftime('%H:%M')}"
        puts "   Status: #{booking.status} (#{status})"
        puts "   Duration: #{booking.duration_hours} hours"
        puts
      end
    end
  end

  def cancel_time_based_booking
    puts "\n--- Cancel Time-based Booking ---"
    
    bookings = @time_manager.all_time_based_bookings.select { |b| !b.cancelled? }
    if bookings.empty?
      puts "No active time-based bookings to cancel."
      return
    end
    
    puts "Active Time-based Bookings:"
    bookings.each_with_index do |booking, index|
      puts "#{index + 1}. #{booking.user.name} -> #{booking.resource.name}"
      puts "   Time: #{booking.start_time.strftime('%Y-%m-%d %H:%M')} - #{booking.end_time.strftime('%H:%M')}"
    end
    
    choice = get_user_input("Select booking to cancel (number): ").to_i - 1
    return unless valid_choice?(choice, bookings)
    
    selected_booking = bookings[choice]
    
    begin
      @time_manager.cancel_booking(selected_booking)
      puts "Successfully cancelled time-based booking for '#{selected_booking.resource.name}'"
    rescue BookingError => e
      puts "Cancellation failed: #{e.message}"
    end
  end

  def save_data
    puts "\n--- Save Data ---"
    begin
      Persistence.save_data(
        users: @users,
        resources: @resources,
        booking_manager: @manager,
        time_based_manager: @time_manager
      )
    rescue => e
      puts "Failed to save data: #{e.message}"
    end
  end

  def load_data
    puts "\n--- Load Data ---"
    begin
      data = Persistence.load_data
      if data
        @users = data[:users]
        @resources = data[:resources]
        @manager = data[:booking_manager]
        @time_manager = data[:time_based_manager]
        puts "Data loaded successfully!"
      else
        puts "Failed to load data"
      end
    rescue => e
      puts "Error loading data: #{e.message}"
    end
  end
end
