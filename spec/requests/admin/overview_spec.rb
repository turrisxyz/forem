require "rails_helper"

RSpec.describe "/admin", type: :request do
  let(:super_admin) { create(:user, :super_admin) }

  before do
    sign_in super_admin
    allow(FeatureFlag).to receive(:enabled?).and_call_original
  end

  describe "Last deployed and Latest Commit ID card" do
    before do
      ForemInstance.instance_variable_set(:@deployed_at, nil)
    end

    after do
      ForemInstance.instance_variable_set(:@deployed_at, nil)
    end

    it "shows the correct value if the Last deployed time is available" do
      stub_const("ENV", ENV.to_h.merge("HEROKU_RELEASE_CREATED_AT" => "Some date"))

      get admin_path

      expect(response.body).to include(ENV["HEROKU_RELEASE_CREATED_AT"])
    end
  end

  describe "analytics" do
    subject(:body) { response.body }

    before do
      Timecop.freeze("2019-04-30T12:00:00Z")
      get admin_path
    end

    after { Timecop.return }

    it { is_expected.to include("Analytics and trends") }
    it { is_expected.to include("Yesterday") }
    xit { is_expected.to include("Apr 23") }

    xit "displays correct number of posts from past week" do
      create(:article, published_at: Time.zone.today)
      create(:article, published_at: 1.day.ago)
      create(:article, published_at: 7.days.ago)
      create(:article, published_at: 8.days.ago)
      get admin_path

      expect(body).to include "2</span> Posts"
    end

    it "displays correct number of comments from past week" do
      create(:comment, created_at: Time.zone.today)
      create(:comment, created_at: 1.day.ago)
      create(:comment, created_at: 8.days.ago)
      get admin_path

      expect(body).to include "1</span> Comments"
    end

    it "displays correct number of reactions from past week" do
      create(:reaction, created_at: Time.zone.today)
      create(:reaction, created_at: 3.days.ago)
      create(:reaction, created_at: 2.weeks.ago)
      get admin_path

      expect(body).to include "1</span> Reaction"
    end

    it "displays correct number of new members from past week" do
      create(:user, registered_at: Time.zone.today)
      create(:user, registered_at: 2.days.ago)
      create(:user, registered_at: 10.days.ago)
      get admin_path

      expect(body).to include "1</span> New members"
    end

    it "does not display data from previous weeks", :aggregate_failures do
      create(:article, published_at: 8.days.ago)
      create(:comment, created_at: 2.weeks.ago)
      create(:reaction, created_at: 1.month.ago)
      create(:user, registered_at: 10.days.ago)
      get admin_path

      expect(body).to include "0</span> Posts"
      expect(body).to include "0</span> Comments"
      expect(body).to include "0</span> Reactions"
      expect(body).to include "0</span> New members"
    end

    it "does not display data from today", :aggregate_failures do
      create(:article, published_at: Time.zone.today)
      create(:comment, created_at: Time.zone.today)
      create(:reaction, created_at: Time.zone.today)
      create(:user, registered_at: Time.zone.today)
      get admin_path

      expect(body).to include "0</span> Posts"
      expect(body).to include "0</span> Comments"
      expect(body).to include "0</span> Reactions"
      expect(body).to include "0</span> New members"
    end
  end
end
