# -*- coding: utf-8 -*-
class Card
  include ColorLog
  attr_reader :pnr, :userid, :printstamp, :expire, :cardid, :pin, :status
  
  def initialize(data, msg)
    @raw = data
    @msg = msg
    if !data["Kort"]
      raise StandardError, "Card message does not contain key: Kort"
    end
    parse(data["Kort"])
    log(@status)
  end

  def process_card
    if blacklisted?
      return
    end

    case @status
    when "Active"
      log("handle active in case")
      handle_active()
    when "Locked"
      blacklist_card()
      IssuedState.delete_issued_state(@pnr)
      block_patron()
    end
  end

  def block_patron
    log("Block patron")
    begin
      basic_data = Koha.get_basic_data(@pnr)
    rescue => e
      @msg.append_response([__FILE__, __method__, __LINE__, e.message].inspect)
      return
    end
    #Set debarment if user exists in Koha
    begin
      res = Koha.block(basic_data[:borrowernumber]) if basic_data[:borrowernumber]
    rescue => e
      @msg.append_response([__FILE__, __method__, __LINE__, e.message].inspect)
    end
    log(res)
  end

  def handle_active
    log("handle active")
    begin
      basic_data = Koha.get_basic_data(@pnr)
    rescue => e
      @msg.append_response([__FILE__, __method__, __LINE__, e.message].inspect)
      return
    end
    #Does user exist in Koha?
    if basic_data[:borrowernumber]
      log("User exists in Koha")
      #uppdatera giltighetsdatatum i gukort2-log
      begin
        Koha.update({
          borrowernumber: basic_data[:borrowernumber],
          cardnumber: @cardnumber,
          patronuserid: @userid,
          dateexpiry: @expire,
          msgtype: "card",
          pin: @pin})
        IssuedState.set_issued_state(pnr, Date.parse(@expire))
      rescue => e
        @msg.append_response([__FILE__, __method__, __LINE__, e.message].inspect)
      end
    else
      log("User does NOT exist in Koha")
      # Det finns ingen sådan användare i Koha, uppdatera error log med eventuella fel
      
    end
  end

  def blacklist_card 
    log('blacklisting card')
    BlacklistedCardNumber.create(card_number:  @cardnumber)
  end

  def blacklisted?
    log('check blacklisted')
    #return true if no such record exists
    !BlacklistedCardNumber.where(card_number: @cardnumber).empty?
  end

  def parse(data)
    owner = data["Kortinnehavare"]
    @pnr = owner["Personnummer"]
    @userid = owner["Kontonamn"]
    @printstamp = Time.parse(data["Utskrivet"])
    @expire = data["Giltighetsdatum"]
    @cardid = data["MifareID"]
    @cardnumber = data["Nummerserie3"]
    # Nummerserie 1-2 ?!?
    @pin = data["PIN"]
    @status = data["Status"]
  end

  def as_json(opt = {})
    {
      pnr: @pnr,
      cardnumber: @cardnumber,
      userid: @userid,
      printstamp: @printstamp,
      expire: @expire,
      cardid: @cardid,
      pin: @pin,
      status: @status
    }
  end

  
end
