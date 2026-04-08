# CLI Lab Booking System (Week 1) — Beginner Notes

This project is a tiny booking system written in **plain Ruby** (no Rails).
It models three main “things”:

- **User**: a person who wants to book something
- **Resource**: the thing being booked (projector, microscope, etc.)
- **Booking**: the reservation that connects a user to a resource

The program runs in the terminal (CLI). The goal is to practice backend thinking:
store data, enforce rules, raise errors, and write tests.

---

## How to run it

From the folder that contains `lab_booking/`, run:

```bash
# Run the tests (checks the rules automatically)
ruby lab_booking/test/test_booking.rb

# Run the demo (prints a short story of booking + conflict + cancel)
ruby lab_booking/app.rb
```

---

## Folder / file map (what each file is for)

- `app.rb`
  - A simple “demo script” that creates users/resources and shows the required sequence.
- `user.rb`
  - Defines the `User` class.
- `resource.rb`
  - Defines the `Resource` class.
- `booking.rb`
  - Defines the `Booking` class and the booking rules.
- `booking_manager.rb`
  - (Extension) A `BookingManager` that stores bookings in an array and can list active bookings.
- `constants.rb`
  - Stores shared constant values like roles and booking statuses.
- `errors.rb`
  - Stores custom error classes like `BookingError`.
- `test/test_booking.rb`
  - Automated tests using Minitest (built into Ruby).
