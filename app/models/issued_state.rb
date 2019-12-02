class IssuedState < ApplicationRecord
  UNKNOWN_EXPIRATION_DELAY=2.months
  
  def self.has_issued_state?(pnr, for_time = nil)
    time = for_time ? for_time : Time.now

    state = IssuedState.where(pnr: pnr).first
    if !state
      return false
    end

    if state.expiration_date > time
      return true
    end

    false
  end

  def self.set_issued_state(pnr, expiration_date = nil)
    if !expiration_date
      expiration_date = Time.now + UNKNOWN_EXPIRATION_DELAY
    end
    previous_state = IssuedState.where(pnr: pnr).first
    if previous_state
      previous_state.update(expiration_date: expiration_date)
    else
      IssuedState.create(pnr: pnr, expiration_date: expiration_date)
    end
  end

  def self.delete_issued_state(pnr)
    previous_state = IssuedState.where(pnr: pnr).first
    if previous_state
      previous_state.destroy
    end
  end
end
