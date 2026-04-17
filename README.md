# CLI Lab Booking System - Enhanced with Advanced Features

This project is a comprehensive booking system written in **plain Ruby** (no Rails).
It models three main entities:

- **User**: a person who wants to book something (students, assistants, instructors)
- **Resource**: the thing being booked (projector, microscope, laptop, etc.)
- **Booking**: the reservation that connects a user to a resource

The program runs in the terminal (CLI) with both simple and advanced booking capabilities.
The goal is to practice backend thinking: store data, enforce rules, raise errors, and write comprehensive tests.

---

## Features

### Core Features
- Simple resource booking with conflict prevention
- Role-based access control (students and assistants can book)
- Booking cancellation with resource availability restoration
- Comprehensive error handling and validation

### Advanced Features (Stretch Tasks)
- **Interactive CLI Menu**: User-friendly interface with 13 menu options
- **Time-based Booking**: Schedule resources with specific time slots and overlap prevention
- **Resource Search**: Filter resources by category (lab, equipment, network)
- **Data Persistence**: Save and load booking data to/from JSON files
- **Enhanced Testing**: Comprehensive test suite with edge case coverage

---

## How to run it

From the `lab_booking/` directory, run:

```bash
# Run all tests
ruby -I. test/test_booking.rb && ruby -I. test/test_time_based_booking.rb && ruby -I. test/test_persistence.rb && ruby -I. test/test_enhanced_functionality.rb

# Run individual test suites
ruby -I. test/test_booking.rb              # Core functionality tests
ruby -I. test/test_time_based_booking.rb   # Time-based booking tests
ruby -I. test/test_persistence.rb           # Data persistence tests
ruby -I. test/test_enhanced_functionality.rb # Enhanced features tests

# Run the interactive CLI application (recommended)
ruby interactive_app.rb

# Run the original demo (simple booking sequence)
ruby app.rb

# Run all tests with the test runner
ruby run_tests.rb
```

---

## Interactive CLI Menu

The enhanced CLI provides these options:

### Basic Operations
1. List all resources
2. List available resources  
3. Search resources by category
4. Book a resource (simple)
5. Cancel a booking
6. List active bookings
7. List all bookings

### Time-based Booking
8. Book a resource with time slot
9. List time-based bookings
10. Cancel time-based booking

### Data Management
11. Save data to file
12. Load data from file
13. Exit

---

## Folder / File Structure

### Core Files
- `app.rb` - Original demo script showing basic booking sequence
- `interactive_app.rb` - Enhanced interactive CLI application
- `user.rb` - User class with role-based permissions
- `resource.rb` - Resource class with time-based booking support
- `booking.rb` - Simple booking class and rules
- `booking_manager.rb` - Manages simple bookings
- `constants.rb` - Shared constants (roles, statuses)
- `errors.rb` - Custom error classes

### Advanced Features
- `cli.rb` - Interactive CLI interface with menu system
- `time_based_booking.rb` - Time-based booking class with overlap detection
- `time_based_booking_manager.rb` - Manages time-based bookings
- `persistence.rb` - Data save/load functionality using JSON

### Test Files
- `test/test_booking.rb` - Core functionality tests
- `test/test_time_based_booking.rb` - Time-based booking tests
- `test/test_persistence.rb` - Data persistence tests
- `test/test_enhanced_functionality.rb` - Enhanced features tests
- `run_tests.rb` - Test runner script

---

## Usage Examples

### Simple Booking
```bash
ruby interactive_app.rb
# Select option 4 (Book a resource)
# Choose a user and resource from the lists
```

### Time-based Booking
```bash
ruby interactive_app.rb  
# Select option 8 (Book a resource with time slot)
# Enter date, start time, and duration
# System checks for conflicts automatically
```

### Data Persistence
```bash
ruby interactive_app.rb
# Select option 11 (Save data to file)
# Data is saved to lab_booking_data.json
# Use option 12 to load saved data
```

---

## Technical Details

### Booking Rules
- Only users with "student" or "assistant" roles can create bookings
- Resources cannot be double-booked during the same time period
- Bookings have "active" or "cancelled" status
- Cancelled bookings free up the resource for new bookings

### Time-based Features
- Bookings require start time, end time, and duration
- Overlap prevention ensures no conflicting time slots
- Current time detection shows which bookings are active now
- Support for bookings ranging from minutes to days

### Data Persistence
- JSON format for human-readable data storage
- Automatic backup creation before data clearing
- Error handling for corrupted data files
- Preserves all booking relationships and time slots

---

## Testing

The project includes comprehensive test coverage:

- **6 core functionality tests** - Basic booking rules
- **17 time-based booking tests** - Advanced scheduling features  
- **9 persistence tests** - Data save/load functionality
- **11 enhanced functionality tests** - Additional features

All tests use Minitest (built into Ruby) and verify:
- Business rule enforcement
- Error handling
- Edge cases
- Data integrity

---
