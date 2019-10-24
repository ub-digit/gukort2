class Message < ApplicationRecord
	attr_reader :xml, :queue_name

  def append_response(response_message)
    update_attribute(:response, self.response + "\n" + response_message)
  end
end
