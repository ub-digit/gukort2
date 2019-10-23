class Card
  include ColorLog
  attr_reader :pnr, :userid, :printstamp, :expire, :cardid, :pin, :status
  
  def initialize(data, msgid)
    @raw = data
    @msgid = msgid
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
        delete_from_issued_state()
        block_patron()
    end
  end

  def block_patron
    log("Block patron")
    basic_data = Koha.get_basic_data(@pnr)
    #Set debarment if user exists in Koha
    res = Koha.block(basic_data[:borrowernumber]) if basic_data[:borrowernumber]
    log(res)
  end

  def handle_active
    log("handle active")
    basic_data = Koha.get_basic_data(@pnr)
    #Does user exist in Koha?
    if basic_data[:borrowernumber]
      log("User exists in Koha")
      #uppdatera giltighetsdatatum i gukort2-log
       state_record = IssuedState.where(pnr: @pnr).first
      if state_record
        state_record.update(expiration_date: Date.parse(@expire))
        Koha.update(basic_data[:borrowernumber], @cardnumber, @userid, @expire, @pin)
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

  def delete_from_issued_state
    log('delete user')
    IssuedState.where(pnr: @pnr).first.destroy
  end

  def add_to_issued_state
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
