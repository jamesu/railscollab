ActiveSupport::Dependencies.load_once_paths.reject! do |path|
  path =~ /^#{Regexp.escape File.dirname(__FILE__)}/
end
