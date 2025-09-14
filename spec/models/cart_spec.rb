require 'rails_helper'
require 'sidekiq/testing'

Sidekiq::Testing.fake!

RSpec.describe Cart, type: :model do
  context 'when validating' do
    it 'validates numericality of total_price' do
      cart = described_class.new(total_price: -1)
      expect(cart.valid?).to be_falsey
      expect(cart.errors[:total_price]).to include("must be greater than or equal to 0")
    end
  end

  describe '#mark_as_abandoned' do
    before do
      MarkCartAsAbandonedJob.jobs.clear
      RemoveAbandonedCartJob.jobs.clear
    end

    let(:shopping_cart) { create(:cart) }

    it 'marks the shopping cart as abandoned if inactive for a certain time' do
      shopping_cart.update(last_interaction_at: 3.hours.ago)
      expect { shopping_cart.mark_as_abandoned }.to change { shopping_cart.abandoned? }.from(false).to(true)
    end

    context 'job scheduling' do
      context 'when there are no jobs marked for execution' do
        it 'schedules a new job for removal' do
          shopping_cart.update_columns(status: 'active', last_interaction_at: 3.hours.ago)
          expect { shopping_cart.mark_as_abandoned }.to change { RemoveAbandonedCartJob.jobs.size }.by(1)
          expect(shopping_cart.reload.next_removed_job_jid).not_to be_nil
        end
      end

      context 'when there is a previous RemoveAbandonedCartJob scheduled' do
        it 'removes the old job and set a new one' do
          shopping_cart.update_columns(status: 'active', next_removed_job_jid: '123asd456')
          shopping_cart.reload
          shopping_cart.mark_as_abandoned
          expect(shopping_cart.next_removed_job_jid).not_to be_nil
          expect(shopping_cart.next_removed_job_jid).not_to eq('123asd456')
        end
      end
    end
  end

  describe '#remove_if_abandoned' do
    let(:shopping_cart) { create(:cart, last_interaction_at: 7.days.ago) }

    it 'removes the shopping cart if abandoned for a certain time' do
      shopping_cart.mark_as_abandoned
      expect { shopping_cart.remove_if_abandoned }.to change { Cart.count }.by(-1)
    end
  end

  describe '#schedule_abandoned_check' do

    before do
      MarkCartAsAbandonedJob.jobs.clear
      RemoveAbandonedCartJob.jobs.clear
    end

    context 'when there are no previous jobs scheduled' do
      it 'schedule a new MarkCartAsAbandonedJob job for the cart' do
        Cart.skip_callback(:save, :after, :schedule_abandoned_check)
        shopping_cart = create(:cart, last_interaction_at: Time.current, next_abandoned_job_jid: nil, next_removed_job_jid: nil)
        Cart.set_callback(:save, :after, :schedule_abandoned_check)

        shopping_cart.send(:schedule_abandoned_check)
        shopping_cart.reload
        expect(MarkCartAsAbandonedJob.jobs.size).to eq(1)
        expect(shopping_cart.next_abandoned_job_jid).not_to be_nil
      end
    end

    context 'when there is a RemoveAbandonedCartJob scheduled' do
      it 'removes the old scheduling and set a new MarkCartAsAbandonedJob job' do
        Cart.skip_callback(:save, :after, :schedule_abandoned_check)
        shopping_cart = create(:cart, last_interaction_at: Time.current, next_abandoned_job_jid: nil, next_removed_job_jid: '123asd456')
        Cart.set_callback(:save, :after, :schedule_abandoned_check)

        expect { shopping_cart.send(:schedule_abandoned_check) }.to change { shopping_cart.next_removed_job_jid }.from('123asd456').to(nil)
        expect(shopping_cart.reload.next_abandoned_job_jid).not_to be_nil
      end
    end

    context 'when there is a MarkCartAsAbandonedJob scheduled' do
      it 'removes the old job and schedule a new MarkCartAsAbandonedJob' do
        Cart.skip_callback(:save, :after, :schedule_abandoned_check)
        shopping_cart = create(:cart, last_interaction_at: Time.current, next_abandoned_job_jid: nil, next_removed_job_jid: '123asd456')
        Cart.set_callback(:save, :after, :schedule_abandoned_check)

        shopping_cart.send(:schedule_abandoned_check)
        shopping_cart.reload

        expect(shopping_cart.next_abandoned_job_jid).not_to eq('123asd456')
        expect(shopping_cart.next_abandoned_job_jid).not_to be_nil
      end
    end
  end

  describe '#destroy_sidekiq_job' do
    let(:shopping_cart) { create(:cart) }

    it 'removes the job given its JID' do
      jid = MarkCartAsAbandonedJob.perform_in(1.hour, shopping_cart.id)
      expect(MarkCartAsAbandonedJob.jobs.map { |j| j['jid'] }).to include(jid)

      shopping_cart.send(:destroy_sidekiq_job, jid)

      scheduled_job_after = Sidekiq::ScheduledSet.new.find_job(jid)
      expect(scheduled_job_after).to be_nil
    end

    it 'does nothing if the job with given JID does not exist' do
      expect { shopping_cart.send(:destroy_sidekiq_job, 'random-non-existent-jid') }.not_to raise_error
    end
  end

  describe '#serializable_hash' do
    let(:shopping_cart) { create(:cart, :with_2_products) }

    it 'expect to return the correct serialization format' do
      result = shopping_cart.serializable_hash
      expect(result).to include(id: shopping_cart.id, total_price: shopping_cart.total_price)
      expect(result[:products].size).to eq(2)

      result[:products].each do |product|
          expect(product).to include(
            id: product[:id],
            name: product[:name],
            quantity: product[:quantity],
            unit_price: product[:unit_price],
            total_price: product[:total_price]
          )
      end
    end
  end

  describe '#update_total_price' do
    let(:shopping_cart) { create(:cart) }

    it 'expect to update the cart total price' do
      product1 = create(:product, price: BigDecimal("10.0"))
      product2 = create(:product, price: BigDecimal("12.0"))
      create(:cart_product, cart: shopping_cart, product: product1, quantity: 2)
      create(:cart_product, cart: shopping_cart, product: product2, quantity: 3)

      shopping_cart.reload.update_total_price
      expected_total = BigDecimal("10.0") * 2 + BigDecimal("12.0") * 3
      expect(shopping_cart.reload.total_price).to eq(expected_total)
    end
  end
end
