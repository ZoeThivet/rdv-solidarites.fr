# frozen_string_literal: true

class CreateAgentTerritorialAccessRight < ActiveRecord::Migration[6.1]
  def change
    create_table :agent_territorial_access_rights do |t|
      t.belongs_to :agent, null: false, foreign_key: true
      t.belongs_to :territory, null: false, foreign_key: true
      t.boolean :allow_to_manage_teams, default: false

      t.timestamps
    end

    data_to_insert = []
    Agent.all.each do |agent|
      agent.organisations.flat_map(&:territory).uniq.each do |territory|
        data_to_insert << {
          agent_id: agent.id,
          territory_id: territory.id,
          allow_to_manage_teams: AgentTerritorialRole.exists?(territory: territory, agent: agent),
          created_at: Time.zone.now,
          updated_at: Time.zone.now
        }
      end
      #AgentTerritorialAccessRight.create(territory: agent.organisations.first.territory, agent: agent)
    end

    AgentTerritorialAccessRight.insert_all(data_to_insert)
  end
end
