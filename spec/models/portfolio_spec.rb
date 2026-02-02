# == Schema Information
#
# Table name: portfolios
#
#  id         :integer          not null, primary key
#  name       :string
#  path       :string
#  tagline    :text
#  active     :boolean          default(TRUE)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

RSpec.describe Portfolio, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
