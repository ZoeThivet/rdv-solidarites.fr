# frozen_string_literal: true

require "rails_helper"

RSpec.describe Outlook::CreateEventJob, type: :job do
  let(:organisation) { create(:organisation, id: 10) }
  let(:motif) { create(:motif, name: "Super Motif", location_type: :phone) }
  # We need to create a fake agent to initialize a RDV as they have a validation on agents which prevents us to control the data in its AgentsRdv
  let(:fake_agent) { create(:agent) }
  let(:agent) { create(:agent, microsoft_graph_token: "token") }
  let(:rdv) { create(:rdv, id: 20, motif: motif, organisation: organisation, starts_at: Time.zone.parse("2023-01-01 11h00"), duration_in_min: 30, agents: [fake_agent]) }
  let!(:agents_rdv) { create(:agents_rdv, id: 12, agent: agent, rdv: rdv) }

  let(:expected_headers) do
    {
      "Accept" => "application/json",
      "Authorization" => "Bearer token",
      "Content-Type" => "application/json",
      "Expect" => "",
      "Return-Client-Request-Id" => "true",
      "User-Agent" => "RDVSolidarites",
    }
  end
  let(:expected_body) do
    {
      subject: "Super Motif",
      body: {
        contentType: "HTML",
        content: "plus d'infos dans RDV Solidarités: http://www.rdv-solidarites-test.localhost/admin/organisations/10/rdvs/20",
      },
      start: {
        dateTime: "2023-01-01T11:00:00+01:00",
        timeZone: "Europe/Paris",
      },
      end: {
        dateTime: "2023-01-01T11:30:00+01:00",
        timeZone: "Europe/Paris",
      },
      location: {
        displayName: "Par téléphone",
      },
    }
  end

  context "when the event is created" do
    before do
      stub_request(:post, "https://graph.microsoft.com/v1.0/me/Events")
        .with(
          body: expected_body,
          headers: expected_headers
        )
        .to_return(status: 200, body: { id: "event_id" }.to_json, headers: {})

      described_class.perform_now(agents_rdv)
    end

    it "update the outlook_id of the agents_rdv" do
      expect(agents_rdv.outlook_id).to eq("event_id")
    end
  end

  context "when the event cannot be created" do
    before do
      stub_request(:post, "https://graph.microsoft.com/v1.0/me/Events")
        .with(
          body: expected_body,
          headers: expected_headers
        )
        .to_return(status: 404, body: { error: { code: "TerribleError", message: "Quelle terrible erreur" } }.to_json, headers: {})

      described_class.perform_now(agents_rdv)
    end

    stub_sentry_events

    it "sends the error to Sentry" do
      expect(agents_rdv.outlook_id).to eq(nil)

      expect(sentry_events.last.message).to eq("Outlook API error for AgentsRdv 12: Quelle terrible erreur")
    end
  end
end
