class DateTime
  # @api public
  def self.to_mongo(value)
    value.to_time.utc
  end

  # @api public
  def self.from_mongo(value)
    value.to_datetime
  end
end # DateTime
