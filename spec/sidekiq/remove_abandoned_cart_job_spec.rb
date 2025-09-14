require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe RemoveAbandonedCartJob, type: :job do
  let!(:cart) { create(:cart, last_interaction_at: 7.days.ago, status: 'abandoned') }

  before { RemoveAbandonedCartJob.clear }

  describe "enqueuing" do
    it 'enqueues the job' do
      expect { RemoveAbandonedCartJob.perform_async(cart.id) }.to change { RemoveAbandonedCartJob.jobs.size }.by(1)
    end
  end

  describe "#perform" do
    it 'remove the cart if it was abandoned for more the allowed' do
      Sidekiq::Testing.inline! do

        expect { RemoveAbandonedCartJob.perform_async(cart.id) }.to change { Cart.all.size }.by(-1)
      end
    end

    it 'does not change the cart status if abandoned for the allowed interval' do
      cart.update(last_interaction_at: 5.days.ago)
      Sidekiq::Testing.inline! do
        RemoveAbandonedCartJob.perform_async(cart.id)
        expect(Cart.all.size).to eq(1)
      end
    end

    it 'does nothing if cart is not valid' do
      Sidekiq::Testing.inline! do
        expect { RemoveAbandonedCartJob.perform_async(99999) }.not_to raise_error
      end
    end

    it 'does not remove active carts' do
      cart.update(last_interaction_at: 7.days.ago, status: 'active')
      RemoveAbandonedCartJob.perform_async(cart.id)
      expect(Cart.all.size).to eq(1)
    end
  end
end
