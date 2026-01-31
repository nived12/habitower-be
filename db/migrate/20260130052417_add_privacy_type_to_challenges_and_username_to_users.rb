class AddPrivacyTypeToChallengesAndUsernameToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column(:challenges, :privacy_type, :string, null: false, default: "public")
    add_index(:challenges, :privacy_type)

    add_column(:users, :username, :string)
    add_index(:users, :username, unique: true)
  end
end
