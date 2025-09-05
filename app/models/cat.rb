class Cat < ApplicationRecord
  belongs_to :user
  after_create :set_initial_level

  # ユーザーのポイントと猫のレベルの対応関係
  LEVEL_THRESHOLDS = {
    1 => 0,
    2 => 50,
    3 => 150,
    4 => 300,
  }.freeze

  def update_level
    current_points = user.points
    new_level = 1

    LEVEL_THRESHOLDS.sort_by { |_, required_points| required_points }.reverse_each do |level, required_points|
      if current_points >= required_points
        new_level = level
        break
      end
    end
    self.update(level: new_level)
  end

  private

  def set_initial_level
    self.update(level: 1)
  end
end