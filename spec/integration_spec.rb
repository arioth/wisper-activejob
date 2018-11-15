require 'pry'

RSpec.describe 'integration tests:' do
  let(:publisher) do
    Class.new do
      include Wisper::Publisher

      def run
        broadcast(:it_happened, 'hello, world')
      end
    end.new
  end

  let(:subscriber) do
    Class.new do
      def self.it_happened
        # noop
      end
    end
  end

  let(:adapter) { ActiveJob::Base.queue_adapter }

  before do
    ActiveJob::Base.queue_adapter = :test
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  context 'when broadcaster is plain object' do
    it 'puts job on ActiveJob queue' do
      publisher.subscribe(subscriber, async: Wisper::ActiveJobBroadcaster.new)
      publisher.run
      expect(adapter.enqueued_jobs.size).to eq 1
    end

    it 'customizes the job class' do
      class CustomWrapper < Wisper::ActiveJobBroadcaster::Wrapper; end

      publisher.subscribe(subscriber, async: Wisper::ActiveJobBroadcaster.new)
      publisher.run
      expect(adapter.enqueued_jobs.size).to eq 1
      expect(adapter.enqueued_jobs.first[:job]).to eq(Wisper::ActiveJobBroadcaster::Wrapper)

      ActiveJob::Base.queue_adapter.enqueued_jobs.clear

      Wisper::ActiveJobBroadcaster.broadcast_with(CustomWrapper)
      publisher.run
      expect(adapter.enqueued_jobs.size).to eq 1
      expect(adapter.enqueued_jobs.first[:job]).to eq(CustomWrapper)
    end
  end

  context 'when broadcaster is async and passes options' do
    it 'puts job on ActiveJob queue' do
      pending('Pending until wisper support for async options is published')

      publisher.subscribe(subscriber, async: { queue: 'default' })
      publisher.run
      expect(adapter.enqueued_jobs.size).to eq 1
    end
  end
end
