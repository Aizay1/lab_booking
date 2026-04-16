require 'json'
require 'fileutils'
require_relative "user"
require_relative "resource"
require_relative "booking"
require_relative "booking_manager"
require_relative "time_based_booking"
require_relative "time_based_booking_manager"
require_relative "constants"

class Persistence
  DATA_FILE = 'lab_booking_data.json'

  def self.save_data(users:, resources:, booking_manager:, time_based_manager: nil)
    data = {
      users: users.map { |user| serialize_user(user) },
      resources: resources.map { |resource| serialize_resource(resource) },
      bookings: booking_manager.all_bookings.map { |booking| serialize_booking(booking) },
      time_based_bookings: time_based_manager ? time_based_manager.all_time_based_bookings.map { |booking| serialize_time_based_booking(booking) } : [],
      saved_at: Time.now.iso8601
    }

    File.write(DATA_FILE, JSON.pretty_generate(data))
    puts "Data saved to #{DATA_FILE}"
  end

  def self.load_data
    return nil unless File.exist?(DATA_FILE)

    begin
      data = JSON.parse(File.read(DATA_FILE))
      
      users = data['users'].map { |user_data| deserialize_user(user_data) }
      resources = data['resources'].map { |resource_data| deserialize_resource(resource_data) }
      
      # Create managers
      booking_manager = BookingManager.new
      time_based_manager = TimeBasedBookingManager.new
      
      # Restore regular bookings
      data['bookings'].each do |booking_data|
        user = users.find { |u| u.id == booking_data['user_id'] }
        resource = resources.find { |r| r.id == booking_data['resource_id'] }
        
        if user && resource
          booking = Booking.new(user: user, resource: resource)
          # Restore status if cancelled
          if booking_data['status'] == BookingStatuses::CANCELLED
            booking.cancel
          end
        end
      end
      
      # Restore time-based bookings
      data['time_based_bookings'].each do |booking_data|
        user = users.find { |u| u.id == booking_data['user_id'] }
        resource = resources.find { |r| r.id == booking_data['resource_id'] }
        
        if user && resource
          start_time = Time.parse(booking_data['start_time'])
          end_time = Time.parse(booking_data['end_time'])
          
          booking = TimeBasedBooking.new(
            user: user,
            resource: resource,
            start_time: start_time,
            end_time: end_time
          )
          
          # Restore status if cancelled
          if booking_data['status'] == BookingStatuses::CANCELLED
            booking.cancel
          end
        end
      end
      
      puts "Data loaded from #{DATA_FILE} (saved: #{data['saved_at']})"
      
      {
        users: users,
        resources: resources,
        booking_manager: booking_manager,
        time_based_manager: time_based_manager
      }
    rescue JSON::ParserError => e
      puts "Error parsing data file: #{e.message}"
      nil
    rescue => e
      puts "Error loading data: #{e.message}"
      nil
    end
  end

  def self.backup_data
    if File.exist?(DATA_FILE)
      backup_file = "#{DATA_FILE}.backup.#{Time.now.strftime('%Y%m%d_%H%M%S')}"
      FileUtils.cp(DATA_FILE, backup_file)
      puts "Data backed up to #{backup_file}"
    else
      puts "No data file to backup"
    end
  end

  def self.clear_data
    if File.exist?(DATA_FILE)
      backup_data
      File.delete(DATA_FILE)
      puts "Data file cleared"
    else
      puts "No data file to clear"
    end
  end

  def self.data_exists?
    File.exist?(DATA_FILE)
  end

  private

  def self.serialize_user(user)
    {
      id: user.id,
      name: user.name,
      role: user.role
    }
  end

  def self.serialize_resource(resource)
    {
      id: resource.id,
      name: resource.name,
      category: resource.category
    }
  end

  def self.serialize_booking(booking)
    {
      user_id: booking.user.id,
      resource_id: booking.resource.id,
      status: booking.status,
      created_at: booking.created_at.strftime('%Y-%m-%dT%H:%M:%S%z')
    }
  end

  def self.serialize_time_based_booking(booking)
    {
      user_id: booking.user.id,
      resource_id: booking.resource.id,
      status: booking.status,
      created_at: booking.created_at.strftime('%Y-%m-%dT%H:%M:%S%z'),
      start_time: booking.start_time.strftime('%Y-%m-%dT%H:%M:%S%z'),
      end_time: booking.end_time.strftime('%Y-%m-%dT%H:%M:%S%z')
    }
  end

  def self.deserialize_user(user_data)
    User.new(
      id: user_data['id'],
      name: user_data['name'],
      role: user_data['role']
    )
  end

  def self.deserialize_resource(resource_data)
    Resource.new(
      id: resource_data['id'],
      name: resource_data['name'],
      category: resource_data['category']
    )
  end
end
