class AddDragonflyThumbFields < ActiveRecord::Migration
  def change
    add_column :tests, :screenshot_thumbnail_uid, :string
    add_column :tests, :screenshot_baseline_thumbnail_uid, :string
    add_column :tests, :screenshot_diff_thumbnail_uid, :string
    
    add_column :baselines, :screenshot_thumbnail_uid, :string
  end
end
