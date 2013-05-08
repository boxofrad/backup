# encoding: utf-8

require File.expand_path('../spec_helper.rb', __FILE__)
require 'rubygems/dependency_installer'

describe 'Backup::CLI' do
  let(:cli)     { Backup::CLI }
  let(:s)       { sequence '' }

  before  { @argv_save = ARGV }
  after   { ARGV.replace(@argv_save) }

  describe '#perform' do
    let(:model_a) { Backup::Model.new(:test_trigger_a, 'test label a') }
    let(:model_b) { Backup::Model.new(:test_trigger_b, 'test label b') }
    let(:s) { sequence '' }

    after { Backup::Model.all.clear }

    describe 'setting logger options' do
      let(:logger_options) { Backup::Logger.instance_variable_get(:@config).dsl }

      before do
        Backup::Config.expects(:update).in_sequence(s)

        Backup::Config.expects(:load_config!).in_sequence(s)

        Backup::Logger.expects(:start!).in_sequence(s)

        model_a.expects(:perform!).in_sequence(s)
        Backup::Logger.expects(:clear!).in_sequence(s)
        model_b.expects(:perform!).in_sequence(s)
        Backup::Logger.expects(:clear!).in_sequence(s)
      end

      it 'configures console and logfile loggers by default' do
        expect do
          ARGV.replace(['perform', '-t', 'test_trigger_a,test_trigger_b'])
          cli.start
        end.not_to raise_error

        logger_options.console.quiet.should be(false)
        logger_options.logfile.enabled.should be_true
        logger_options.logfile.log_path.should == ''
        logger_options.syslog.enabled.should be(false)
      end

      it 'configures only the syslog' do
        expect do
          ARGV.replace(
            ['perform', '-t', 'test_trigger_a,test_trigger_b',
            '--quiet', '--no-logfile', '--syslog']
          )
          cli.start
        end.not_to raise_error

        logger_options.console.quiet.should be_true
        logger_options.logfile.enabled.should be_nil
        logger_options.logfile.log_path.should == ''
        logger_options.syslog.enabled.should be_true
      end

      it 'forces console logging' do
        expect do
          ARGV.replace(
            ['perform', '-t', 'test_trigger_a,test_trigger_b', '--no-quiet']
          )
          cli.start
        end.not_to raise_error

        logger_options.console.quiet.should be_nil
        logger_options.logfile.enabled.should be_true
        logger_options.logfile.log_path.should == ''
        logger_options.syslog.enabled.should be(false)
      end

      it 'forces the logfile and syslog to be disabled' do
        expect do
          ARGV.replace(
            ['perform', '-t', 'test_trigger_a,test_trigger_b',
              '--no-logfile', '--no-syslog']
          )
          cli.start
        end.not_to raise_error

        logger_options.console.quiet.should be(false)
        logger_options.logfile.enabled.should be_nil
        logger_options.logfile.log_path.should == ''
        logger_options.syslog.enabled.should be_nil
      end

      it 'configures the log_path' do
        expect do
          ARGV.replace(
            ['perform', '-t', 'test_trigger_a,test_trigger_b',
              '--log-path', 'my/log/path']
          )
          cli.start
        end.not_to raise_error

        logger_options.console.quiet.should be(false)
        logger_options.logfile.enabled.should be_true
        logger_options.logfile.log_path.should == 'my/log/path'
        logger_options.syslog.enabled.should be(false)
      end
    end # describe 'setting logger options'

    describe 'setting triggers' do
      let(:model_c) { Backup::Model.new(:test_trigger_c, 'test label c') }

      before do
        Backup::Logger.expects(:configure).in_sequence(s)

        Backup::Config.expects(:update).in_sequence(s)

        Backup::Config.expects(:load_config!).in_sequence(s)

        Backup::Logger.expects(:start!).in_sequence(s)
      end

      it 'performs a given trigger' do
        model_a.expects(:perform!).in_sequence(s)
        Backup::Logger.expects(:clear!).in_sequence(s)
        model_b.expects(:perform!).never

        expect do
          ARGV.replace(
            ['perform', '-t', 'test_trigger_a']
          )
          cli.start
        end.not_to raise_error
      end

      it 'performs multiple triggers' do
        model_a.expects(:perform!).in_sequence(s)
        Backup::Logger.expects(:clear!).in_sequence(s)
        model_b.expects(:perform!).in_sequence(s)
        Backup::Logger.expects(:clear!).in_sequence(s)

        expect do
          ARGV.replace(
            ['perform', '-t', 'test_trigger_a,test_trigger_b']
          )
          cli.start
        end.not_to raise_error
      end

      it 'performs multiple models that share a trigger name' do
        model_c.expects(:perform!).in_sequence(s)
        Backup::Logger.expects(:clear!).in_sequence(s)

        model_d = Backup::Model.new(:test_trigger_c, 'test label d')
        model_d.expects(:perform!).in_sequence(s)
        Backup::Logger.expects(:clear!).in_sequence(s)

        expect do
          ARGV.replace(
            ['perform', '-t', 'test_trigger_c']
          )
          cli.start
        end.not_to raise_error
      end

      it 'performs unique models only once, in the order first found' do
        model_a.expects(:perform!).in_sequence(s)
        Backup::Logger.expects(:clear!).in_sequence(s)
        model_b.expects(:perform!).in_sequence(s)
        Backup::Logger.expects(:clear!).in_sequence(s)
        model_c.expects(:perform!).in_sequence(s)
        Backup::Logger.expects(:clear!).in_sequence(s)

        expect do
          ARGV.replace(
            ['perform', '-t',
             'test_trigger_a,test_trigger_b,test_trigger_c,test_trigger_b']
          )
          cli.start
        end.not_to raise_error
      end

      it 'performs unique models only once, in the order first found (wildcard)' do
        model_a.expects(:perform!).in_sequence(s)
        Backup::Logger.expects(:clear!).in_sequence(s)
        model_b.expects(:perform!).in_sequence(s)
        Backup::Logger.expects(:clear!).in_sequence(s)
        model_c.expects(:perform!).in_sequence(s)
        Backup::Logger.expects(:clear!).in_sequence(s)

        expect do
          ARGV.replace(
            ['perform', '-t', 'test_trigger_*']
          )
          cli.start
        end.not_to raise_error
      end

    end # describe 'setting triggers'

    describe 'failure to prepare for backups' do
      before do
        Backup::Logger.expects(:configure).in_sequence(s)

        Backup::Config.expects(:update).in_sequence(s)

        Backup::Logger.expects(:start!).never

        model_a.expects(:perform!).never
        model_b.expects(:perform!).never
        Backup::Logger.expects(:clear!).never
      end

      describe 'when errors are raised while loading config.rb' do
        before do
          Backup::Config.expects(:load_config!).in_sequence(s).
              raises('config load error')
        end

        it 'aborts with status code 3 and logs messages to the console only' do

          Backup::Logger.expects(:error).in_sequence(s).with do |err|
            err.should be_a(Backup::Errors::CLIError)
            err.message.should match(/config load error/)
          end

          Backup::Logger.expects(:abort!).in_sequence(s)

          expect do
            ARGV.replace(
              ['perform', '-t', 'test_trigger_a']
            )
            cli.start
          end.to raise_error(SystemExit) {|exit| exit.status.should be(3) }
        end
      end

      describe 'when no models are found for the given triggers' do
        before do
          Backup::Config.expects(:load_config!).in_sequence(s)
        end

        it 'aborts and logs messages to the console only' do
          Backup::Logger.expects(:error).in_sequence(s).with do |err|
            err.should be_a(Backup::Errors::CLIError)
            err.message.should match(
              /No Models found for trigger\(s\) 'test_trigger_foo'/
            )
          end

          Backup::Logger.expects(:abort!).in_sequence(s)

          expect do
            ARGV.replace(
              ['perform', '-t', 'test_trigger_foo']
            )
            cli.start
          end.to raise_error(SystemExit) {|exit| exit.status.should be(3) }
        end
      end
    end # describe 'failure to prepare for backups'

    describe 'exit codes when backups have errors or warnings' do
      before do
        Backup::Config.stubs(:load_config!)
        Backup::Logger.stubs(:start!)
      end

      specify 'when a job has warnings' do
        model_a.expects(:perform!).in_sequence(s)
        Backup::Logger.expects(:has_warnings?).in_sequence(s).returns(true)
        Backup::Logger.expects(:has_errors?).in_sequence(s).returns(false)
        Backup::Logger.expects(:clear!).in_sequence(s)
        model_b.expects(:perform!).in_sequence(s)
        Backup::Logger.expects(:has_errors?).in_sequence(s).returns(false)
        Backup::Logger.expects(:clear!).in_sequence(s)

        expect do
          ARGV.replace(
            ['perform', '-t', 'test_trigger_a,test_trigger_b']
          )
          cli.start
        end.to raise_error(SystemExit) {|err| err.status.should be(1) }
      end

      specify 'when a job has errors' do
        model_a.expects(:perform!).in_sequence(s)
        Backup::Logger.expects(:has_warnings?).in_sequence(s).returns(false)
        Backup::Logger.expects(:has_errors?).in_sequence(s).returns(true)
        Backup::Logger.expects(:clear!).in_sequence(s)
        model_b.expects(:perform!).in_sequence(s)
        Backup::Logger.expects(:has_warnings?).in_sequence(s).returns(false)
        Backup::Logger.expects(:clear!).in_sequence(s)

        expect do
          ARGV.replace(
            ['perform', '-t', 'test_trigger_a,test_trigger_b']
          )
          cli.start
        end.to raise_error(SystemExit) {|err| err.status.should be(2) }
      end

      specify 'when a jobs have errors and warnings' do
        model_a.expects(:perform!).in_sequence(s)
        Backup::Logger.expects(:has_warnings?).in_sequence(s).returns(false)
        Backup::Logger.expects(:has_errors?).in_sequence(s).returns(true)
        Backup::Logger.expects(:clear!).in_sequence(s)
        model_b.expects(:perform!).in_sequence(s)
        Backup::Logger.expects(:has_warnings?).in_sequence(s).returns(true)
        Backup::Logger.expects(:clear!).in_sequence(s)

        expect do
          ARGV.replace(
            ['perform', '-t', 'test_trigger_a,test_trigger_b']
          )
          cli.start
        end.to raise_error(SystemExit) {|err| err.status.should be(2) }
      end
    end # describe 'exit codes when backups have errors or warnings'

    describe '--check' do
      it 'runs the check command' do
        cli.any_instance.expects(:check).raises(SystemExit)
        expect do
          ARGV.replace(
            ['perform', '-t', 'test_trigger_foo', '--check']
          )
          cli.start
        end.to raise_error(SystemExit)
      end
    end # describe '--check'

  end # describe '#perform'

  describe '#check' do
    it 'fails if errors are raised' do
      Backup::Config.stubs(:load_config!).raises('an error')

      out, err = capture_io do
        ARGV.replace(['check'])
        expect do
          cli.start
        end.to raise_error(SystemExit) {|exit| expect( exit.status ).to be(1) }
      end

      expect( err ).to match(/RuntimeError: an error/)
      expect( err ).to match(/\[error\] Configuration Check Failed/)
      expect( out ).to be_empty
    end

    it 'fails if warnings are issued' do
      Backup::Config.stubs(:load_config!).with do
        Backup::Logger.warn 'warning message'
      end

      out, err = capture_io do
        ARGV.replace(['check'])
        expect do
          cli.start
        end.to raise_error(SystemExit) {|exit| expect( exit.status ).to be(1) }
      end

      expect( err ).to match(/\[warn\] warning message/)
      expect( err ).to match(/\[error\] Configuration Check Failed/)
      expect( out ).to be_empty
    end

    it 'succeeds if there are no errors or warnings' do
      Backup::Config.stubs(:load_config!)

      out, err = capture_io do
        ARGV.replace(['check'])
        expect do
          cli.start
        end.to raise_error(SystemExit) {|exit| expect( exit.status ).to be(0) }
      end

      expect( err ).to be_empty
      expect( out ).to match(/\[info\] Configuration Check Succeeded/)
    end

    it 'updates path to config.rb if given' do
      Backup::Config.stubs(:load_config!)
      Backup::Logger.stubs(:abort!) # suppress output

      ARGV.replace(['check', '--config-file', '/my/config.rb'])
      expect do
        cli.start
      end.to raise_error(SystemExit) {|exit| expect( exit.status ).to be(0) }

      expect( Backup::Config.config_file ).to eq '/my/config.rb'
    end
  end # describe '#check'

  describe '#generate:model' do
    before do
      @tmpdir = Dir.mktmpdir('backup_spec')
      SandboxFileUtils.activate!(@tmpdir)
    end

    after do
      FileUtils.rm_r(@tmpdir, :force => true, :secure => true)
    end

    context 'when given a config_path' do
      context 'when no config file exists' do
        it 'should create both a config and a model under the given path' do
          Dir.chdir(@tmpdir) do |path|
            model_file  = File.join(path, 'custom', 'models', 'my_test_trigger.rb')
            config_file = File.join(path, 'custom', 'config.rb')

            out, err = capture_io do
              ARGV.replace(['generate:model',
                 '--config-path', File.join(path, 'custom'),
                 '--trigger', 'my test#trigger'
              ])
              cli.start
            end

            err.should be_empty
            out.should == "Generated model file: '#{ model_file }'.\n" +
                "Generated configuration file: '#{ config_file }'.\n"
            File.exist?(model_file).should be_true
            File.exist?(config_file).should be_true
          end
        end
      end

      context 'when a config file already exists' do
        it 'should only create a model under the given path' do
          Dir.chdir(@tmpdir) do |path|
            model_file  = File.join(path, 'custom', 'models', 'my_test_trigger.rb')
            config_file = File.join(path, 'custom', 'config.rb')
            FileUtils.mkdir_p(File.join(path, 'custom'))
            FileUtils.touch(config_file)

            out, err = capture_io do
              ARGV.replace(['generate:model',
                 '--config-path', File.join(path, 'custom'),
                 '--trigger', 'my+test@trigger'
              ])
              cli.start
            end

            err.should be_empty
            out.should == "Generated model file: '#{ model_file }'.\n"
            File.exist?(model_file).should be_true
          end
        end

        it 'should abort if --config-path is the path to config.rb itself' do
          Dir.chdir(@tmpdir) do |path|
            config_file = File.join(path, 'custom', 'config.rb')
            FileUtils.mkdir_p(File.join(path, 'custom'))
            FileUtils.touch(config_file)

            out, err = capture_io do
              ARGV.replace(['generate:model',
                 '--config-path', config_file,
                 '--trigger', 'foo'
              ])
              expect do
                cli.start
              end.to raise_error(SystemExit)
            end

            err.should == "--config-path should be a directory, not a file.\n"
            out.should be_empty
          end

        end
      end

      context 'when a model file already exists' do
        it 'should prompt to overwrite the model under the given path' do
          Dir.chdir(@tmpdir) do |path|
            model_file  = File.join(path, 'models', 'test_trigger.rb')
            config_file = File.join(path, 'config.rb')

            cli::Helpers.expects(:overwrite?).with(model_file).returns(false)

            out, err = capture_io do
              ARGV.replace(['generate:model',
                  '--config-path', path,
                  '--trigger', 'test_trigger'
              ])
              cli.start
            end

            err.should be_empty
            out.should == "Generated configuration file: '#{ config_file }'.\n"
            File.exist?(config_file).should be_true
            File.exist?(model_file).should be_false
          end
        end
      end

    end # context 'when given a config_path'

    context 'when not given a config_path' do
      it 'should create both a config and a model under the root path' do
        Dir.chdir(@tmpdir) do |path|
          Backup::Config.update(:root_path => path)
          model_file  = File.join(path, 'models', 'test_trigger.rb')
          config_file = File.join(path, 'config.rb')

          out, err = capture_io do
            ARGV.replace(['generate:model', '--trigger', 'test_trigger'])
            cli.start
          end

          err.should be_empty
          out.should == "Generated model file: '#{ model_file }'.\n" +
              "Generated configuration file: '#{ config_file }'.\n"
          File.exist?(model_file).should be_true
          File.exist?(config_file).should be_true
        end
      end
    end

    it 'should include the correct option values' do
      options = <<-EOS.lines.to_a.map(&:strip).map {|l| l.partition(' ') }
        databases (mongodb, mysql, postgresql, redis, riak)
        storages (cloud_files, dropbox, ftp, local, ninefold, rsync, s3, scp, sftp)
        syncers (cloud_files, rsync_local, rsync_pull, rsync_push, s3)
        encryptors (gpg, openssl)
        compressors (bzip2, custom, gzip, lzma, pbzip2)
        notifiers (campfire, hipchat, jaconda, mail, prowl, pushover, twitter)
      EOS

      out, err = capture_io do
        ARGV.replace(['help', 'generate:model'])
        cli.start
      end

      expect( err ).to be_empty
      options.each do |option|
        expect( out ).to match(/#{ option[0] }.*#{ option[2] }/)
      end
    end

  end # describe '#generate:model'

  describe '#generate:config' do
    before do
      @tmpdir = Dir.mktmpdir('backup_spec')
      SandboxFileUtils.activate!(@tmpdir)
    end

    after do
      FileUtils.rm_r(@tmpdir, :force => true, :secure => true)
    end

    context 'when given a config_path' do
      it 'should create a config file in the given path' do
        Dir.chdir(@tmpdir) do |path|
          config_file = File.join(path, 'custom', 'config.rb')

          out, err = capture_io do
            ARGV.replace(['generate:config',
                '--config-path', File.join(path, 'custom'),
            ])
            cli.start
          end

          err.should be_empty
          out.should == "Generated configuration file: '#{ config_file }'.\n"
          File.exist?(config_file).should be_true
        end
      end
    end

    context 'when not given a config_path' do
      it 'should create a config file in the root path' do
        Dir.chdir(@tmpdir) do |path|
          Backup::Config.update(:root_path => path)
          config_file = File.join(path, 'config.rb')

          out, err = capture_io do
            ARGV.replace(['generate:config'])
            cli.start
          end

          err.should be_empty
          out.should == "Generated configuration file: '#{ config_file }'.\n"
          File.exist?(config_file).should be_true
        end
      end
    end

    context 'when a config file already exists' do
      it 'should prompt to overwrite the config file' do
        Dir.chdir(@tmpdir) do |path|
          Backup::Config.update(:root_path => path)
          config_file = File.join(path, 'config.rb')

          cli::Helpers.expects(:overwrite?).with(config_file).returns(false)

          out, err = capture_io do
            ARGV.replace(['generate:config'])
            cli.start
          end

          err.should be_empty
          out.should be_empty
          File.exist?(config_file).should be_false
        end
      end
    end

  end # describe '#generate:config'

  describe '#decrypt' do

    it 'should perform OpenSSL decryption' do
      ARGV.replace(['decrypt', '--encryptor', 'openssl',
                    '--in', 'in_file',
                    '--out', 'out_file',
                    '--base64', '--salt',
                    '--password-file', 'pwd_file'])

      cli::Helpers.expects(:exec!).with(
        "openssl aes-256-cbc -d -base64 -pass file:pwd_file -salt " +
        "-in 'in_file' -out 'out_file'"
      )
      cli.start
    end

    it 'should omit -pass option if no --password-file given' do
      ARGV.replace(['decrypt', '--encryptor', 'openssl',
                    '--in', 'in_file',
                    '--out', 'out_file',
                    '--base64', '--salt'])

      cli::Helpers.expects(:exec!).with(
        "openssl aes-256-cbc -d -base64  -salt " +
        "-in 'in_file' -out 'out_file'"
      )
      cli.start
    end

    it 'should perform GnuPG decryption' do
      ARGV.replace(['decrypt', '--encryptor', 'gpg',
                    '--in', 'in_file',
                    '--out', 'out_file'])

      cli::Helpers.expects(:exec!).with(
        "gpg -o 'out_file' -d 'in_file'"
      )
      cli.start
    end

    it 'should show a message if given an invalid encryptor' do
      ARGV.replace(['decrypt', '--encryptor', 'foo',
                    '--in', 'in_file',
                    '--out', 'out_file'])
      out, err = capture_io do
        cli.start
      end
      err.should == ''
      out.should == "Unknown encryptor: foo\n" +
          "Use either 'openssl' or 'gpg'.\n"
    end
  end # describe '#decrypt'

  describe '#dependencies' do
    let(:dep_a) {
      stub('dep_a',
        :name         => 'dep-a',
        :requirements => ['~> 1.2.3'],
        :used_for     => 'Provides A'
      )
    }
    let(:dep_b) {
      stub('dep_b',
        :name         => 'dep-b',
        :requirements => ['>= 2.1.0', '<= 2.5.0'],
        :used_for     => 'Provides B'
      )
    }
    let(:dep_c) {
      stub('dep_c',
        :name         => 'dep-c',
        :requirements => ['~> 3.4.5'],
        :used_for     => 'Provides C',
        :dependencies => [dep_a]
      )
    }

    before do
      Backup::Dependency.stubs(:all).returns([dep_a, dep_b, dep_c])
      Backup::Dependency.stubs(:find).with('dep-a').returns(dep_a)
      Backup::Dependency.stubs(:find).with('dep-b').returns(dep_b)
      Backup::Dependency.stubs(:find).with('dep-c').returns(dep_c)
      Backup::Dependency.stubs(:find).with('foo').returns(nil)
    end

    it 'shows help and exits when no arguments are given' do
      cli::Helpers.expects(:exec!).with("#{ $0 } help dependencies").
          raises(SystemExit)

      ARGV.replace(['dependencies'])
      expect do
        cli.start
      end.to raise_error(SystemExit)
    end

    describe '#dependencies --list' do
      it 'lists all dependencies and exits' do
        ARGV.replace(['dependencies', '--list'])
        out, err = capture_io do
          expect do
            cli.start
          end.to raise_error(SystemExit) {|exit| exit.status.should be(0) }
        end
        err.should == ''
        out.should == <<-EOS.gsub(/^ +/, '')

          Gem Name:      dep-a
          Version:       ~> 1.2.3
          Used for:      Provides A
          -------------------------

          Gem Name:      dep-b
          Version:       >= 2.1.0, <= 2.5.0
          Used for:      Provides B
          -------------------------

          Gem Name:      dep-c
          Version:       ~> 3.4.5
          Used for:      Provides C
          -------------------------
        EOS
      end
    end

    describe '#dependencies --install' do
      before do
        cli::Helpers.stubs(:bundler_loaded?).returns(false)
      end

      it 'aborts with message if Bundler is loaded' do
        cli::Helpers.expects(:bundler_loaded?).returns(true)

        ARGV.replace(['dependencies', '--install', 'dep-b'])
        out, err = capture_io do
          expect do
            cli.start
          end.to raise_error(SystemExit) {|exit| exit.status.should be(1) }
        end
        err.should match(/Bundler Detected/)
        out.should be_empty
      end

      it 'aborts with message if gem name is invalid' do
        ARGV.replace(['dependencies', '--install', 'foo'])
        out, err = capture_io do
          expect do
            cli.start
          end.to raise_error(SystemExit) {|exit| exit.status.should be(1) }
        end
        err.should == "'foo' is not a Backup dependency.\n"
        out.should be_empty
      end

      it 'aborts with message if dependencies are not installed' do
        dep_a.expects(:installed?).returns(false)

        ARGV.replace(['dependencies', '--install', 'dep-c'])
        out, err = capture_io do
          expect do
            cli.start
          end.to raise_error(SystemExit) {|exit| exit.status.should be(1) }
        end
        err.should == <<-EOS.gsub(/^ +/, '')
          The 'dep-c' gem requires 'dep-a'
          Please install this first using the following command:
          > backup dependencies --install dep-a
        EOS
        out.should be_empty
      end

      it 'installs the gem if dependencies are met' do
        dep_a.expects(:installed?).returns(true)
        dep_c.expects(:install!)

        ARGV.replace(['dependencies', '--install', 'dep-c'])
        out, err = capture_io do
          cli.start
        end
        err.should be_empty
        out.should be_empty
      end
    end # describe '#dependencies --install'

    describe '#dependencies --installed' do
      it 'aborts with message if gem name is invalid' do
        ARGV.replace(['dependencies', '--installed', 'foo'])
        out, err = capture_io do
          expect do
            cli.start
          end.to raise_error(SystemExit) {|exit| exit.status.should be(1) }
        end
        err.should == "'foo' is not a Backup dependency.\n"
        out.should be_empty
      end

      context 'when dependencies are met' do
        before do
          dep_a.expects(:installed?).returns(true)
        end

        it 'returns message if gem is installed' do
          dep_c.expects(:installed?).returns(true)

          ARGV.replace(['dependencies', '--installed', 'dep-c'])
          out, err = capture_io do
            cli.start
          end
          err.should be_empty
          out.should == "'dep-c' is installed.\n"
        end

        it 'returns error message if gem is not installed' do
          dep_c.expects(:installed?).returns(false)

          ARGV.replace(['dependencies', '--installed', 'dep-c'])
          out, err = capture_io do
            expect do
              cli.start
            end.to raise_error(SystemExit) {|exit| exit.status.should be(1) }
          end
          err.should == <<-EOS.gsub(/^ +/, '')
            'dep-c' is not installed.
            To install the gem, issue the following command:
            > backup dependencies --install dep-c
            Please try again after installing the missing dependency.
          EOS
          out.should be_empty
        end
      end # context 'when dependencies are met'

      context 'when dependencies are not met' do
        before do
          dep_a.expects(:installed?).returns(false)
          dep_c.expects(:installed?).never
        end

        it 'returns error message that the dependency is not installed' do
          ARGV.replace(['dependencies', '--installed', 'dep-c'])
          out, err = capture_io do
            expect do
              cli.start
            end.to raise_error(SystemExit) {|exit| exit.status.should be(1) }
          end
          err.should == <<-EOS.gsub(/^ +/, '')
            'dep-c' requires the 'dep-a' gem.
            To install the gem, issue the following command:
            > backup dependencies --install dep-a
            Please try again after installing the missing dependency.
          EOS
          out.should be_empty
        end
      end # context 'when dependencies are met'
    end # describe '#dependencies --installed'
  end # describe '#dependencies'

  describe '#version' do
    specify 'using `backup version`' do
      ARGV.replace ['version']
      out, err = capture_io do
        cli.start
      end
      err.should be_empty
      out.should == "Backup #{ Backup::Version.current }\n"
    end

    specify 'using `backup -v`' do
      ARGV.replace ['-v']
      out, err = capture_io do
        cli.start
      end
      err.should be_empty
      out.should == "Backup #{ Backup::Version.current }\n"
    end
  end

  describe 'Helpers' do
    let(:helpers) { Backup::CLI::Helpers }

    describe '#overwrite?' do

      it 'prompts user and accepts confirmation' do
        File.expects(:exist?).with('a/path').returns(true)
        $stderr.expects(:print).with(
          "A file already exists at 'a/path'.\nDo you want to overwrite? [y/n] "
        )
        $stdin.expects(:gets).returns("yes\n")

        expect( helpers.overwrite?('a/path') ).to be_true
      end

      it 'prompts user and accepts cancelation' do
        File.expects(:exist?).with('a/path').returns(true)
        $stderr.expects(:print).with(
          "A file already exists at 'a/path'.\nDo you want to overwrite? [y/n] "
        )
        $stdin.expects(:gets).returns("no\n")

        expect( helpers.overwrite?('a/path') ).to be_false
      end

      it 'returns true if path does not exist' do
        File.expects(:exist?).with('a/path').returns(false)
        $stderr.expects(:print).never
        expect( helpers.overwrite?('a/path') ).to be_true
      end
    end

  end # describe 'Helpers'

end
