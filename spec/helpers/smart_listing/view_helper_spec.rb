# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SmartListing::ViewHelper do
  describe '#smart_listing_create' do

    def build_list(collection: {})
      double(collection: collection, setup: nil).tap do |list|
        allow(SmartListing::Base).to receive(:new).and_return(list)
      end
    end

    it 'create a list with params and cookies' do
      controller = Test::UsersController.new
      list = build_list

      expect(list).to receive(:setup).with(controller.params, controller.cookies) # rubocop:disable RSpec/MessageSpies

      controller.smart_listing_create
    end

    it 'assign a list in smart listings with the name' do
      controller = Test::UsersController.new
      list = build_list

      controller.smart_listing_create

      expect(controller.smart_listings[:users]).to eq list
    end

    it 'return the collection of the list' do
      controller = Test::UsersController.new
      collection1 = double
      collection2 = double
      build_list(collection: collection1)

      controller.smart_listing_create(collection: collection2)

      actual = controller.smart_listings[:users].collection
      expect(actual).to eq collection1
    end
  end

  describe '#smart_listing' do
    it 'give the list with name' do
      controller = Test::UsersController.new
      list = double
      controller.smart_listings = { test: list }
      expect(controller.smart_listing(:test)).to eq list
    end
  end
end
