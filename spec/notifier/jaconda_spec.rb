# encoding: utf-8

require File.expand_path('../../spec_helper.rb', __FILE__)

describe Backup::Notifier::Jaconda do
  let(:model) { Backup::Model.new(:test_trigger, 'test label') }
  let(:notifier) do
    Backup::Notifier::Jaconda.new(model) do |notifier|
      notifier.subdomain   = 'me.jaconda.im'
      notifier.room_id     = 'room_one'
      notifier.room_token  = 'room_token'
      notifier.sender_name = 'sender name'
    end
  end

  it 'should be a subclass of Notifier::Base' do
    Backup::Notifier::Jaconda.
      superclass.should == Backup::Notifier::Base
  end

  describe '#initialize' do
    after { Backup::Notifier::Jaconda.clear_defaults! }

    it 'should load pre-configured defaults through Base' do
      Backup::Notifier::Jaconda.any_instance.expects(:load_defaults!)
      notifier
    end

    it 'should pass the model reference to Base' do
      notifier.instance_variable_get(:@model).should == model
    end

    context 'when no pre-configured defaults have been set' do
      it 'should use the values given' do
        notifier.subdomain.should   == 'me.jaconda.im'
        notifier.room_token.should  == 'room_token'
        notifier.room_id.should     == 'room_one'
        notifier.sender_name.should == 'sender name'
        notifier.on_success.should  == true
        notifier.on_warning.should  == true
        notifier.on_failure.should  == true
      end

      it 'should use default values if none are given' do
        notifier = Backup::Notifier::Jaconda.new(model)
        notifier.subdomain.should   be_nil
        notifier.room_token.should  be_nil
        notifier.room_id.should     be_nil
        notifier.sender_name.should be_nil
        notifier.on_success.should  == true
        notifier.on_warning.should  == true
        notifier.on_failure.should  == true
      end
    end # context 'when no pre-configured defaults have been set'

    context 'when pre-configured defaults have been set' do
      before do
        Backup::Notifier::Jaconda.defaults do |n|
          n.subdomain      = 'before.jaconda.im'
          n.room_token     = 'before_token'
          n.room_id        = 'before_room'
          n.sender_name    = 'before name'
          n.on_failure     = false
        end
      end

      it 'should use pre-configured defaults' do
        notifier = Backup::Notifier::Jaconda.new(model)

        notifier.subdomain.should   == 'before.jaconda.im'
        notifier.room_token.should  == 'before_token'
        notifier.room_id.should     == 'before_room'
        notifier.sender_name.should == 'before name'
        notifier.on_success.should  == true
        notifier.on_warning.should  == true
        notifier.on_failure.should  == false
      end

      it 'should override pre-configured defaults' do
        notifier = Backup::Notifier::Jaconda.new(model) do |n|
          n.subdomain   = 'after.jaconda.im'
          n.room_token  = 'after_token'
          n.room_id     = 'after_room'
          n.sender_name = 'after name'
          n.on_failure  = true
        end

        notifier.subdomain.should   == 'after.jaconda.im'
        notifier.room_token.should  == 'after_token'
        notifier.room_id.should     == 'after_room'
        notifier.sender_name.should == 'after name'
        notifier.on_success.should  == true
        notifier.on_warning.should  == true
        notifier.on_failure.should  == true
      end
    end # context 'when pre-configured defaults have been set'
  end # describe '#initialize'

  describe '#notify!' do
    context 'when status is :success' do
      it 'should send Success message' do
        notifier.expects(:send_message).with(
          '[Backup::Success] test label (test_trigger)'
        )
        notifier.send(:notify!, :success)
      end
    end

    context 'when status is :warning' do
      it 'should send Warning message' do
        notifier.expects(:send_message).with(
          '[Backup::Warning] test label (test_trigger)'
        )
        notifier.send(:notify!, :warning)
      end
    end

    context 'when status is :failure' do
      it 'should send Failure message' do
        notifier.expects(:send_message).with(
          '[Backup::Failure] test label (test_trigger)'
        )
        notifier.send(:notify!, :failure)
      end
    end
  end # describe '#notify!'

  describe '#send_message' do
    before do
      notifier.subdomain   = 'aha.jaconda.im'
      notifier.room_id     = 'TravelTavern'
      notifier.room_token  = 'SmellMyCheese'
      notifier.sender_name = 'Alan Partridge'
    end

    it 'sends the message using the jaconda API' do
      Jaconda::Notification.expects(:authenticate).with({
        :subdomain  => 'aha.jaconda.im',
        :room_id    => 'TravelTavern',
        :room_token => 'SmellMyCheese'
      })

      Jaconda::Notification.expects(:notify).with({
        :text        => 'Knowing me, knowing you',
        :sender_name => 'Alan Partridge'
      })

      notifier.send(:send_message, 'Knowing me, knowing you')
    end
  end
end
