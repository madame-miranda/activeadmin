require 'rails_helper'

class DefaultPolicy < ApplicationPolicy
  class Scope

    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope
    end
  end
end

describe ActiveAdmin::PunditAdapter do

  describe "full integration" do

    let(:application) { ActiveAdmin::Application.new }
    let(:namespace) { ActiveAdmin::Namespace.new(application, "Admin") }
    let(:resource) { namespace.register(Post) }
    let(:auth) { namespace.authorization_adapter.new(resource, double) }
    let(:default_policy_klass) { DefaultPolicy }
    let(:default_policy_klass_name) { "DefaultPolicy" }

    before do
      namespace.authorization_adapter = ActiveAdmin::PunditAdapter
    end

    it "should initialize the ability stored in the namespace configuration" do
      expect(auth.authorized?(:read, Post)).to eq true
      expect(auth.authorized?(:update, Post)).to eq false
    end

    it "should scope the collection" do
      class RSpec::Mocks::DoublePolicy < ApplicationPolicy
        class Scope < Struct.new(:user, :scope)
          def resolve
            scope
          end
        end
      end

      collection = double
      auth.scope_collection(collection, :read)
      expect(collection).to eq collection
    end

    context 'when Pundit is unable to find policy scope' do
      let(:collection) { double("collection", to_sym: :collection) }
      subject(:scope) { auth.scope_collection(collection, :read) }

      before do
        allow(ActiveAdmin.application).to receive(:pundit_default_policy).and_return default_policy_klass_name
        allow(Pundit).to receive(:policy_scope!) { raise Pundit::NotDefinedError.new }
      end

      it("should return default policy's scope if defined") { is_expected.to eq(collection) }
    end

    context "when Pundit is unable to find policy" do
      let(:record) { double }

      subject(:policy) { auth.retrieve_policy(record) }

      before do
        allow(ActiveAdmin.application).to receive(:pundit_default_policy).and_return default_policy_klass_name
        allow(Pundit).to receive(:policy!) { raise Pundit::NotDefinedError.new }
      end

      it("should return default policy instance") { is_expected.to be_instance_of(default_policy_klass) }
    end
  end

end
