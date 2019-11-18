class Message < ApplicationRecord
	attr_reader :xml, :queue_name

  def append_response(response_message)
    new_response = [self.response, response_message].compact.join("\n")
    update_attribute(:response, new_response)
  end
end
