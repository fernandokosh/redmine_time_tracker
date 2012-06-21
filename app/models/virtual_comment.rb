class VirtualComment < ActiveRecord::Base
  attr_accessible :comments
  belongs_to :time_booking
end