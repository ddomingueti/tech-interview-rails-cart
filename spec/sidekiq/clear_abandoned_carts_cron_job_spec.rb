require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe ClearAbandonedCartsCronJob, type: :job do
  let!(:cart) { create(:cart, last_interaction_at: 7.hours.ago, status: 'active') }

  describe "#perform" do
    it 'mark the cart as abandoned after a valid last_interaction_at interval' do
      Sidekiq::Testing.inline! do
        ClearAbandonedCartsCronJob.perform_async

        expect(cart.reload.status).to eq('abandoned')
      end
    end

    it 'remove the cart if abandoned for more than the valid interval' do
      cart.update_columns(last_interaction_at: 8.days.ago, status: 'abandoned')

      Sidekiq::Testing.inline! do
        expect { ClearAbandonedCartsCronJob.perform_async }.to change { Cart.all.size}.by(-1)
      end
    end
  end
end
