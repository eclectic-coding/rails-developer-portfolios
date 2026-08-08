class AddScreenshotTrackingToPortfolios < ActiveRecord::Migration[8.1]
  def up
    add_column :portfolios, :screenshot_status, :integer, default: 0, null: false
    add_column :portfolios, :screenshot_error, :text
    add_column :portfolios, :screenshot_attempted_at, :datetime
    add_column :portfolios, :screenshot_source, :string
    add_index :portfolios, :screenshot_status

    # Portfolios that already have a screenshot attached predate this tracking;
    # mark them success so the retry sweep doesn't re-generate everything on day one.
    execute <<~SQL
      UPDATE portfolios
      SET screenshot_status = 1
      WHERE id IN (
        SELECT record_id FROM active_storage_attachments
        WHERE record_type = 'Portfolio' AND name = 'site_screenshot'
      )
    SQL
  end

  def down
    remove_column :portfolios, :screenshot_status
    remove_column :portfolios, :screenshot_error
    remove_column :portfolios, :screenshot_attempted_at
    remove_column :portfolios, :screenshot_source
  end
end
