class Card
  attr_reader :pnr, :userid, :printstamp, :expire, :cardid, :pin, :status
  
  def initialize(data)
    @raw = data
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
        handle_active()
      when "Locked"
        blacklist_card()
        delete_from_issued_state()
        block_patron()
        # Sätt GU-spärr i Koha ->
    end
  end

  def block_patron
    log("Block patron")
    basic_data = Patron.get_basic_data(@pnr)
    Patron.block(basic_data[:borrowernumber]) if basic_data[:uniq] == "true"
  end

  def handle_active

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
    issued_states = IssuedState.where(pnr: @pnr)
    issued_states.each do |issued_state|
      issued_state.destroy
    end
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

  def log(msg)
     puts "\033[32m\033[1m#{msg}\e[0m"
  end
end
