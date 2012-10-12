class VirtualComment < ActiveRecord::Base
  attr_accessible :comments
  belongs_to :time_booking

  validates :comments, :length => {:maximum => 255}, :allow_blank => true
end