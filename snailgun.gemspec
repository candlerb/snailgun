Gem::Specification.new do |s|
  s.name = %q{snailgun}
  s.version = "1.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Brian Candler"]
  s.date = %q{2010-10-24}
  s.description = %q{Snailgun accelerates the startup of Ruby applications which require large numbers of libraries}
  s.email = %q{b.candler@pobox.com}
  s.files = [
    "bin/fautotest", "bin/fconsole", "bin/fcucumber", "bin/frake", "bin/fruby", "bin/snailgun",
    "lib/snailgun/server.rb", "README.markdown", "README-snowleopard", "ruby-1.9.2-p0.patch", "textmate.patch", "README-textmate"
  ]
  s.executables = ["fautotest", "fconsole", "fcucumber", "frake", "fruby", "snailgun"]
  s.extra_rdoc_files = ["README.markdown"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/candlerb/snailgun}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{snailgun}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Command-line startup accelerator}
  if s.respond_to? :specification_version then
    s.specification_version = 2
  end
end
