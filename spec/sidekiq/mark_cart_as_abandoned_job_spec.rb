require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe MarkCartAsAbandonedJob, type: :job do
  let!(:cart) { create(:cart, last_interaction_at: 3.hours.ago) }

  before { MarkCartAsAbandonedJob.clear }

  describe "enqueuing" do
    it 'enqueues the job' do
      expect { MarkCartAsAbandonedJob.perform_async(cart.id) }.to change { MarkCartAsAbandonedJob.jobs.size }.by(1)
    end
  end

  describe "#perform" do
    it 'change the cart status to abandoned if a valid last_interaction_at interval' do
      Sidekiq::Testing.inline! do
        MarkCartAsAbandonedJob.perform_async(cart.id)

        expect(cart.reload.abandoned?).to be_truthy
      end
    end

    it 'schedules the RemoveAbandonedCartJob if marked as abandoned' do
      Sidekiq::Testing.inline! do
        MarkCartAsAbandonedJob.perform_async(cart.id)

        expect(cart.reload.abandoned?).to be_truthy
        expect(cart.next_removed_job_jid).not_to be_nil
      end
    end

    it 'does not change the cart status if not valid last_interaction_at interval' do
      cart.update(last_interaction_at: 1.hour.ago)
      Sidekiq::Testing.inline! do
        MarkCartAsAbandonedJob.perform_async(cart.id)

        expect(cart.reload.abandoned?).to be_falsey
      end
    end

    it 'does nothing if cart is not valid' do
      Sidekiq::Testing.inline! do
        expect { MarkCartAsAbandonedJob.perform_async(99999) }.not_to raise_error
      end
    end
  end


end
