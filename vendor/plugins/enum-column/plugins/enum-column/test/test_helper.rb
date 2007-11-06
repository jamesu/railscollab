# =============================================================================
# Include the files required to test Engines.

# Load the default rails test helper - this will load the environment.
require File.dirname(__FILE__) + '/../../../../test/test_helper'

plugin_path = File::dirname(__FILE__) + '/..'
schema_file = plugin_path + "/test/db/schema.rb"
load(schema_file) if File.exist?(schema_file)

# set up the fixtures location to use your engine's fixtures
fixture_path = File.dirname(__FILE__)  + "/fixtures/"
Test::Unit::TestCase.fixture_path = fixture_path
$LOAD_PATH.unshift(Test::Unit::TestCase.fixture_path)
$LOAD_PATH.unshift(File.dirname(__FILE__))
# =============================================================================


