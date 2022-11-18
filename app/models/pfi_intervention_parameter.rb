# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2021 Ekylibre SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: pfi_intervention_parameters
#  id                       :integer          not null, primary key
#
class PfiInterventionParameter < ApplicationRecord
  belongs_to :input, class_name: 'InterventionInput', inverse_of: :pfi_input
  belongs_to :target, class_name: 'InterventionTarget', inverse_of: :pfi_targets
  belongs_to :campaign
  enumerize :nature, in: %i[intervention crop]

  PFI_BASE_URL = if Rails.env.production?
                   "https://alim.agriculture.gouv.fr/"
                 else
                   "https://alim-pprd.agriculture.gouv.fr/"
                 end

  PFI_CHECK_URL = PFI_BASE_URL + 'ift/verifier-traitement-ift/'

  PFI_SEGMENTS_TRANSCODE = { S1: "Traitement de semences",
                             S2: "Biocontrole",
                             S3: "Herbicides",
                             S4: "Insecticides acaricides",
                             S5: "Fongicides bactericides",
                             S6: "Autres" }.freeze

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  # ]VALIDATORS]

  scope :of_campaign, lambda { |campaign|
    where(campaign: campaign)
  }

  scope :of_segment, lambda { |segment|
    where(segment_code: segment.to_s)
  }

  # url to check the pfi computation data on agriculture.gouv.fr
  def check_url
    if !response.nil? && response['id']
      url = PFI_CHECK_URL + response['id'].to_s
    else
      nil
    end
  end

  def segment_name
    PFI_SEGMENTS_TRANSCODE[self.segment_code.to_sym]
  end

end
