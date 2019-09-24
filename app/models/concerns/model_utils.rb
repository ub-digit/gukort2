module ModelUtils
  def self.get_config
    {
      base_url: APP_CONFIG["koha"]["base_url"],
      user: APP_CONFIG["koha"]["user"],
      password: APP_CONFIG["koha"]["password"],
    }
  end
end
