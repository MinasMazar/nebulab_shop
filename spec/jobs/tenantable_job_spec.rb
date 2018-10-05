require 'rails_helper'

RSpec.describe TenantableJob, type: :job do
  describe '#perform' do
    it 'deliver push notification' do
      expect do
        described_class.perform_later
      end.to have_enqueued_job(TenantableJob).on_queue('default')
    end
  end
end
