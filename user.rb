require_relative "errors"
require_relative "constants"

class User
  attr_reader :id, :name, :role

  def initialize(id:, name:, role:)
    raise ValidationError, "User id is required" if id.nil?
    raise ValidationError, "User name is required" if name.nil? || name.strip.empty?
    raise ValidationError, "User role is required" if role.nil? || role.to_s.strip.empty?

    @id = id
    @name = name
    @role = role
  end

  def can_book?
    Roles::BOOKING_ALLOWED.include?(role)
  end
end
