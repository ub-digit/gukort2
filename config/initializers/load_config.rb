if Rails.env == "test"
  secret_config = YAML.load_file("#{Rails.root}/config/config_secret.test.yml")
else
  secret_config = YAML.load_file("#{Rails.root}/config/config_secret.yml")
end
APP_CONFIG = secret_config

def get_config
  {
    base_url: APP_CONFIG["koha"]["base_url"],
    user: APP_CONFIG["koha"]["user"],
    password: APP_CONFIG["koha"]["password"],
    svc_check: APP_CONFIG["koha"]["svc_check"],
    svc_create: APP_CONFIG["koha"]["svc_create"],
    svc_update: APP_CONFIG["koha"]["svc_update"],
  }
end
