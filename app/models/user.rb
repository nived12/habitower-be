class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable,
    :validatable, :jwt_authenticatable,
    jwt_revocation_strategy: self

  has_many :created_challenges, class_name: "Challenge", foreign_key: :creator_id, dependent: :nullify
  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships

  # Set jti on user when dispatching a token so JTIMatcher can revoke on logout
  def jwt_payload
    self.jti = self.class.generate_jti
    save!
    super.merge("jti" => jti)
  end
end
