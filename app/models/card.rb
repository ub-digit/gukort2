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
      if @cardnumber.blank?
        @msg.append_response("Message has no cardnumber")
      else
        log("handle active in case")
        handle_active()
      end
    when "Inactive"
      log("handle inactive in case (PIN update)")
      handle_inactive()
    when "Locked"
      if @cardnumber.blank?
        @msg.append_response("Message has no cardnumber")
      else
        blacklist_card()
        IssuedState.delete_issued_state(@pnr)
        block_patron()
      end
    end
  end

  # Do not update for certain category codes
  def should_update?(categorycode)
    if ["EX", "UX", "FX", "FR", "SR"].include?(categorycode)
      return false
    end
    return true
  end
  
  def block_patron
    log("Block patron")
    begin
      basic_data = Koha.get_basic_data(@pnr)
    rescue => e
      @msg.append_response([__FILE__, __method__, __LINE__, e.message].inspect)
      return
    end
    #Set debarment if user exists in Koha and has a suitable category

    # Abort if category is unsuitable
    if !should_update?(basic_data[:categorycode])
      return
    end

    begin
      if basic_data[:borrowernumber]
        res = Koha.block(basic_data[:borrowernumber])
      end
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
    #Does user exist in Koha and is of a suitable category?
    if basic_data[:borrowernumber]
      # Abort if category is unsuitable for update
      if !should_update?(basic_data[:categorycode])
        return
      end
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
      @msg.append_response("User does not exist in Koha")
      # Det finns ingen sådan användare i Koha, uppdatera error log med eventuella fel
      
    end
  end

  def handle_inactive
    log("handle inactive")
    # Check environment variable to see if we should update PIN for inactive cards
    return if !should_update_inactive

    begin
      basic_data = Koha.get_basic_data(@pnr)
    rescue => e
      @msg.append_response([__FILE__, __method__, __LINE__, e.message].inspect)
      return
    end
    #Does user exist in Koha and is of a suitable category?
    if basic_data[:borrowernumber]
      # Abort if category is unsuitable for update
      if !should_update?(basic_data[:categorycode])
        return
      end
      log("User exists in Koha")
      #uppdatera giltighetsdatatum i gukort2-log
      begin
        Koha.updatepin({
          borrowernumber: basic_data[:borrowernumber],
          msgtype: "updatepin",
          pin: @pin})
      rescue => e
        @msg.append_response([__FILE__, __method__, __LINE__, e.message].inspect)
      end
    else
      log("User does NOT exist in Koha")
      @msg.append_response("User does not exist in Koha")
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

  def should_update_inactive
    # We should accept any version of:
    # true, t, yes, y, 1 in any capitalization
    # Everything else is false
    # ENV does not have to be set
    return false if ENV['UPDATE_INACTIVE_CARDS'].nil?
    return true if [true, "true", "t", "yes", "y", "1"].include?(ENV['UPDATE_INACTIVE_CARDS'].downcase)
    return false
  end
end
