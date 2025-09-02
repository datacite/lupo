# frozen_string_literal: true

# require 'rails_helper'

# describe OrcidAutoUpdateByIdJob, type: :job do
#   let(:user) { create(:user) }
#   subject(:job) { OrcidAutoUpdateByIdJob.perform_later(user.uid) }

#   it 'queues the job' do
#     expect { job }.to have_enqueued_job(OrcidAutoUpdateByIdJob)
#       .on_queue("test_lupo_background")
#   end

#   after do
#     clear_enqueued_jobs
#     clear_performed_jobs
#   end
# end
