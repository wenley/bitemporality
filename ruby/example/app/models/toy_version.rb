require 'bitemporal'

class ToyVersion < ApplicationRecord
  include Bitemporal::Versioned
end
