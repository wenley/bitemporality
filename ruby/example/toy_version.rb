require 'lib/bitemporal'

class ToyVersion < ActiveRecord::Base
  include Bitemporal::Versioned
end
