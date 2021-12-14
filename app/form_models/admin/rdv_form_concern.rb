# frozen_string_literal: true

module Admin::RdvFormConcern
  extend ActiveSupport::Concern

  included do
    attr_accessor :rdv

    delegate(*::Rdv.attribute_names, to: :rdv)
    delegate :motif, :organisation, :agents, :users, to: :rdv
    delegate :overlapping_plages_ouvertures, :overlapping_plages_ouvertures?, to: :rdv
    delegate :rdvs_ending_shortly_before, :rdvs_ending_shortly_before?, to: :rdv_start_coherence
    delegate :rdvs_overlapping_rdv, :rdvs_overlapping_rdv?, to: :rdvs_overlapping

    delegate :errors, to: :rdv

    validate :validate_rdv
    validate :warn_overlapping_plage_ouverture
    validate :warn_rdvs_ending_shortly_before
    validate :warn_rdvs_overlapping_rdv

    attr_accessor :active_warnings_confirm_decision

    def warnings_need_confirmation?
      rdv.errors.keys == [:_warn]
    end
  end

  private

  def validate_rdv
    rdv.validate
  end

  def warn_overlapping_plage_ouverture
    return if active_warnings_confirm_decision

    return true unless overlapping_plages_ouvertures?

    overlapping_plages_ouvertures
      .map { PlageOuverturePresenter.new(_1, agent_context) }
      .each { rdv.errors.add(:_warn, _1.overlaps_rdv_error_message) }
  end

  def warn_rdvs_ending_shortly_before
    return if active_warnings_confirm_decision

    return true unless rdvs_ending_shortly_before?

    rdv_agent_pairs_ending_shortly_before_grouped_by_agent.values.map do
      RdvEndingShortlyBeforePresenter.new(
        rdv: _1.rdv,
        agent: _1.agent,
        rdv_context: rdv,
        agent_context: agent_context
      )
    end.each { rdv.errors.add(:_warn, _1.warning_message) }
  end

  def warn_rdvs_overlapping_rdv
    return if active_warnings_confirm_decision

    return true unless rdvs_overlapping_rdv?

    rdv_agent_pairs_rdvs_overlapping_grouped_by_agent.values.map do
      RdvsOverlappingRdvPresenter.new(
        rdv: _1.rdv,
        agent: _1.agent,
        rdv_context: rdv,
        agent_context: agent_context
      )
    end.each { rdv.errors.add(:_warn, _1.warning_message) }
  end

  def rdv_agent_pairs_ending_shortly_before_grouped_by_agent
    rdvs_ending_shortly_before
      .flat_map do |rdv_before|
        rdv_before.agents.select { rdv.agents.include?(_1) }.map { OpenStruct.new(agent: _1, rdv: rdv_before) }
      end
      .group_by(&:agent)
      .transform_values(&:last)
  end

  def rdv_agent_pairs_rdvs_overlapping_grouped_by_agent
    rdvs_overlapping_rdv
      .flat_map do |rdv_overlapping|
        rdv_overlapping.agents.select { rdv.agents.include?(_1) }.map { OpenStruct.new(agent: _1, rdv: rdv_overlapping) }
      end
      .group_by(&:agent)
      .transform_values(&:last)
  end

  def rdvs_overlapping
    @rdvs_overlapping ||= RdvsOverlapping.new(rdv)
  end

  def rdv_start_coherence
    @rdv_start_coherence ||= RdvStartCoherence.new(rdv)
  end
end
