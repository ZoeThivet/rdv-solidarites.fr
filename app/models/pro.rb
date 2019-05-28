class Pro < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable, :async

  enum role: { user: 0, admin: 1 }

  validates :email, :role, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end

  def initials
    full_name.split.first(2).map(&:first).join.upcase
  end

  def complete?
    first_name.present? && last_name.present?
  end
end
