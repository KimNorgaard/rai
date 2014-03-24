$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
require 'rai'

map('/photos') { run Rai::App }
