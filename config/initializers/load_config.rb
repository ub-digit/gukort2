require 'yaml'
require "erb"

if Rails.env == "test"
  secret_config = YAML.load_file("#{Rails.root}/config/config_secret.test.yml")
else
  secret_config = YAML.load(ERB.new(File.read("#{Rails.root}/config/config_secret.yml")).result)
end
APP_CONFIG = secret_config

def get_koha_config
  {
    base_url: APP_CONFIG["koha"]["base_url"],
    user: APP_CONFIG["koha"]["user"],
    password: APP_CONFIG["koha"]["password"],
    svc_check: APP_CONFIG["koha"]["svc_check"],
    svc_create: APP_CONFIG["koha"]["svc_create"],
    svc_update: APP_CONFIG["koha"]["svc_update"],
    svc_syncuser: APP_CONFIG["koha"]["svc_syncuser"],
  }
end

def get_mq_config
  {
    rest_url: APP_CONFIG["mq"]["rest_url"],
    rest_api_key: APP_CONFIG["mq"]["rest_api_key"]
  }
end

