require './lib/bitemporal'

class ToyModel
  include Bitemporal::Model

  version_class ToyVersion

  def self.from_version(transacted_at:, effective_since:, version:)
    new(version.id)
  end

  def initialize(inner_value)
    @inner_value = inner_value
  end
  attr_reader :inner_value
end
