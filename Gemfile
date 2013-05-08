# encoding: utf-8

source 'http://rubygems.org'

##
# Gemfile.lock controls the dependencies used when running the specs in `spec/`.
#
# backup.gemspec controls the dependencies that will be installed and used by
# the released version of backup. It also controls the dependencies used when
# running the specs in `vagrant/spec`, which are run on the VM.
#
# Whenever Gemfile.lock is updated, `rake gemspec` must be run to sync
# backup.gemspec with Gemfile.lock. All gems in the :production group
# (and their dependencies) will be added to backup.gemspec.
##

# Specify version requirements to control `bundle update` if needed.
group :production do
  gem 'thor'
  gem 'open4'
  gem 'fog'
  gem 'dropbox-sdk', '= 1.5.1' # patched
  gem 'net-ssh'
  gem 'net-scp'
  gem 'net-sftp'
  gem 'parallel'
  gem 'mail'
  gem 'twitter'
  gem 'httparty'
  gem 'prowler'
  gem 'hipchat'
  gem 'jaconda'
end

gem 'rspec'
gem 'mocha'
gem 'timecop'

# Omitted from Travis CI Environment
group :no_ci do
  gem 'guard'
  gem 'guard-rspec'
  gem 'fuubar'

  gem 'rb-fsevent' # Mac OS X
  gem 'rb-inotify' # Linux

  gem 'yard'
  gem 'redcarpet'
end

