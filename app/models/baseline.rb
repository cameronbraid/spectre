class Baseline < ActiveRecord::Base
  belongs_to :suite
  default_scope { order(:created_at) }
  dragonfly_accessor :screenshot do
    copy_to(:screenshot_thumbnail){|a| a.thumb('300x') }
  end
  dragonfly_accessor :screenshot_thumbnail
  validates :key, :name, :browser, :size, :suite, presence: true

  def screenshot_url
    Rails.application.routes.url_helpers.baseline_path(key: self.key, format: 'png')
  end
end
