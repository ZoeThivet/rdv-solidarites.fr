class AddOutlookTokenToAgent < ActiveRecord::Migration[6.1]
  def change
    add_column :agents, :microsoft_graph_token, :text
  end
end
