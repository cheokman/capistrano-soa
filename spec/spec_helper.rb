$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))


require 'rspec'
require 'capistrano'
require 'capistrano-spec'
require 'rspec'
require 'rspec/autorun'




# Add capistrano-spec matchers and helpers to RSpec
RSpec.configure do |config|
  config.include Capistrano::Spec::Matchers
  config.include Capistrano::Spec::Helpers
end

# Require your lib here
require 'capistrano/ext/soa'
