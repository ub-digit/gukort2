class CardMessagesController < ApplicationController
  def create
  	#log incoming message
  	Message.create(xml: request.raw_post, queue_name: "card")
    card = Card.new(params)
    card.process_card()
    render json: card
  end
end
