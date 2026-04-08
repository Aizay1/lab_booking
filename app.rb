require_relative "user"
require_relative "resource"
require_relative "booking_manager"
require_relative "errors"

def print_heading(text)
  puts "\n#{text}"
end

print_heading("Setup users and resources")
users = [
  User.new(id: 1, name: "Hana", role: "student"),
  User.new(id: 2, name: "Nati", role: "assistant")
]

resources = [
  Resource.new(id: 1, name: "Projector", category: "equipment"),
  Resource.new(id: 2, name: "Microscope", category: "lab")
]

manager = BookingManager.new

print_heading("Create one valid booking")
booking1 = manager.create_booking(user: users[0], resource: resources[0])
puts "Booking1 status: #{booking1.status}"
puts "Resource '#{resources[0].name}' available? #{resources[0].available?}"

print_heading("Try conflicting booking for same resource")
begin
  manager.create_booking(user: users[1], resource: resources[0])
rescue BookingError => e
  puts "Blocked as expected: #{e.message}"
end

print_heading("Cancel the first booking")
booking1.cancel
puts "Booking1 status: #{booking1.status}"

print_heading("Resource becomes available again")
puts "Resource '#{resources[0].name}' available? #{resources[0].available?}"

print_heading("List active bookings")
puts manager.active_bookings.map { |b| "#{b.user.name} -> #{b.resource.name} (#{b.status})" }
