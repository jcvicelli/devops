import ConfigParser

# Updating app_name for Sixpack.
config = ConfigParser.RawConfigParser()
sixpackConfig = '/var/lib/newrelic-sixpack.ini'
config.read(sixpackConfig)

if config.has_section('newrelic'):
  config.set('newrelic', 'app_name', 'sixpack-envs')

with open(sixpackConfig, 'wb') as configfile:
  config.write(configfile)


# Updating app_name for Sixpack-Web.
config = ConfigParser.RawConfigParser()
sixpackWebConfig = '/var/lib/newrelic-sixpack-web.ini'
config.read(sixpackWebConfig)

if config.has_section('newrelic'):
  config.set('newrelic', 'app_name', 'sixpack-web-envs')

with open(sixpackWebConfig, 'wb') as configfile:
  config.write(configfile)
