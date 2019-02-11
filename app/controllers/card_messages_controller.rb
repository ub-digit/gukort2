class CardMessagesController < ApplicationController
  def create
    card = Card.new(params)
    render json: card
  end
end
