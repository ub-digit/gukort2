class Message < ApplicationRecord
	attr_reader :xml, :queue_name
end
