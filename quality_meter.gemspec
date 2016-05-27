$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "quality_meter/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "quality_meter"
  s.version     = QualityMeter::VERSION
  s.authors     = ["Arpit Vaishnav"]
  s.email       = ["arpitvaishnav@gmail.com"]
  s.homepage    = "https://github.com/arpitvaishnav/quality_meter"
  s.summary     = "QualityMeter for applications in Rails."
  s.description = "QualityMeter is a common platform for rails application quality controll."

  s.files = Dir["{app,config,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.add_development_dependency "bundler", "~> 1.8"
  s.add_development_dependency "rake", "~> 10.0"

  s.add_runtime_dependency "brakeman" , "~> 3.3"
  s.add_runtime_dependency "metric_fu" ,"~> 4.12"
  s.add_runtime_dependency "terminal-table", "~> 1.5"
end
