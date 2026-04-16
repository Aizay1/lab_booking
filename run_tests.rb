#!/usr/bin/env ruby

puts "=== Running All Lab Booking Tests ==="
puts

test_files = [
  "test/test_booking.rb",
  "test/test_time_based_booking.rb", 
  "test/test_persistence.rb",
  "test/test_enhanced_functionality.rb"
]

total_failures = 0
total_errors = 0

test_files.each_with_index do |test_file, index|
  puts "Running #{index + 1}/#{test_files.length}: #{test_file}"
  puts "-" * 50
  
  result = system("ruby -I. #{test_file}")
  
  if result
    puts "PASSED"
  else
    puts "FAILED"
    total_failures += 1
  end
  
  puts
end

puts "=== Test Summary ==="
if total_failures == 0
  puts "All tests passed! #{test_files.length} test files executed successfully."
else
  puts "#{total_failures} test file(s) failed."
end

exit total_failures
