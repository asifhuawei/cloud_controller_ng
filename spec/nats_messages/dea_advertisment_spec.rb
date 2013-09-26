require "spec_helper"
require "cloud_controller/nats_messages/dea_advertisment"

describe DeaAdvertisement do
  let(:message) do
    {
      "id" => "staging-id",
      "stacks" => ["stack-name"],
      "available_memory" => 1024,
      "app_id_to_count" => {
        "app_id" => 2,
        "app_id_2" => 1
      }
    }
  end

  subject(:ad) { DeaAdvertisement.new(message) }

  describe "#dea_id" do
    its(:dea_id) { should eq "staging-id" }
  end

  describe "#stats" do
    its(:stats) { should eq message }
  end

  describe "#available_memory" do
    its(:available_memory) { should eq 1024 }
  end

  describe "#expired?" do
    let(:now) { Time.now }
    context "when the time since the advertisment is greater than 10 seconds" do
      it "returns false" do
        Timecop.freeze now do
          ad
          Timecop.travel now + 11.seconds do
            expect(ad).to be_expired
          end
        end
      end
    end

    context "when the time since the advertisment is less than or equal to 10 seconds" do
      it "returns false" do
        Timecop.freeze now do
          ad
          Timecop.travel now + 10.seconds do
            expect(ad).to_not be_expired
          end
        end
      end
    end
  end

  describe "#meets_needs?" do
    context "when it has the memory" do
      let(:mem) { 512 }

      context "and it has the stack" do
        let(:stack) { "stack-name" }
        it { expect(ad.meets_needs?(mem, stack)).to be_true }
      end

      context "and it does not have the stack" do
        let(:stack) { "not-a-stack-name" }
        it { expect(ad.meets_needs?(mem, stack)).to be_false }
      end
    end

    context "when it does not have the memory" do
      let(:mem) { 2048 }

      context "and it has the stack" do
        let(:stack) { "stack-name" }
        it { expect(ad.meets_needs?(mem, stack)).to be_false }
      end

      context "and it does not have the stack" do
        let(:stack) { "not-a-stack-name" }
        it { expect(ad.meets_needs?(mem, stack)).to be_false }
      end
    end
  end

  describe "#has_sufficient_memory?" do
    context "when the dea does not have enough memory" do
      it "returns false" do
        expect(ad.has_sufficient_memory?(2048)).to be_false
      end
    end

    context "when the dea has enough memory" do
      it "returns false" do
        expect(ad.has_sufficient_memory?(512)).to be_true
      end
    end
  end

  describe "#has_stack?" do
    context "when the dea has the stack" do
      it "returns false" do
        expect(ad.has_stack?("stack-name")).to be_true
      end
    end

    context "when the dea does not have the stack" do
      it "returns false" do
        expect(ad.has_stack?("not-a-stack-name")).to be_false
      end
    end
  end

  describe "#num_instances_of" do
    it { expect(ad.num_instances_of("app_id")).to eq 2 }
    it { expect(ad.num_instances_of("not_on_dea")).to eq 0 }
  end

  describe "increment_instance_count" do
    it "increment the instance count" do
      expect {
        ad.increment_instance_count("app_id")
      }.to change {
        ad.num_instances_of("app_id")
      }.from(2).to(3)
    end
  end
end