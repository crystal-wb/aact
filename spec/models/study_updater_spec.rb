require 'rails_helper'
require 'securerandom'

describe StudyUpdater do

  describe '#update_studies' do
    before do
      20.times { Study.create(xml: '', nct_id: SecureRandom.hex) }
      Study.all.each { |study| StudyXmlRecord.create(content: '<study></study>', nct_id: study.nct_id) }
    end

    context 'given an array of nct_ids' do
      it 'should re-create all of the specified studies' do
        allow_any_instance_of(ClinicalTrials::Client).to receive(:download_xml_files) {  }

        nct_ids          = Study.pluck(:nct_id)
        created_at_dates = Study.pluck(:created_at)

        updater = described_class.new
        updater.update_studies(nct_ids: nct_ids)

        old_studies_are_gone = (Study.pluck(:created_at) & created_at_dates).length == 0

        expect(old_studies_are_gone).to eq(true)
        expect(Study.count).to eq(20)
      end
    end
  end

end
