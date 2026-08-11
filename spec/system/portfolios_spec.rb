require 'rails_helper'

RSpec.describe "Portfolios", type: :system do
  describe "wiring" do
    let!(:portfolio) { create(:portfolio, name: 'John Doe', path: 'https://johndoe.com', tagline: 'Full Stack Developer', active: true) }

    it "renders the cards frame with infinite-scroll and portfolio-search wired up" do
      visit portfolios_path

      expect(page).to have_turbo_frame("portfolios_cards")
      expect(page).to have_stimulus_controller("infinite-scroll")
      expect(page).to have_stimulus_controller("portfolio-search")
      expect(page).to have_stimulus_target("portfolio-search", "input")
      expect(page).to have_stimulus_action("input->portfolio-search#submit")
      expect(page).to have_stimulus_target("portfolio-search", "clear")
      expect(page).to have_stimulus_action("click->portfolio-search#clear")
    end

    it "does not render the infinite-scroll sentinel when there are no more pages" do
      visit portfolios_path

      expect(page).not_to have_stimulus_target("infinite-scroll", "sentinel")
    end
  end

  describe "infinite scroll", js: true do
    before { create_list(:portfolio, 13, active: true) }

    it "loads the next page of cards when the sentinel scrolls into view" do
      visit portfolios_path

      expect(page).to have_css("turbo-frame#portfolios_cards .card", count: 12)

      page.execute_script(<<~JS)
        document.querySelector('[data-infinite-scroll-target="sentinel"]').scrollIntoView()
      JS

      expect(page).to have_css("turbo-frame#portfolios_cards .card", count: 13)
    end
  end

  describe "live search", js: true do
    let!(:matching) { create(:portfolio, name: "Searchable Dev", tagline: "Ruby", active: true) }
    let!(:other) { create(:portfolio, name: "Someone Else", tagline: "Python", active: true) }

    it "filters cards within the turbo frame and toggles the clear button" do
      visit portfolios_path

      within_turbo_frame("portfolios_cards") do
        expect(page).to have_content("Someone Else")
      end

      fill_in "q", with: "Searchable"

      within_turbo_frame("portfolios_cards") do
        expect(page).to have_content("Searchable Dev")
        expect(page).not_to have_content("Someone Else")
      end

      expect(page).to have_css(".search-clear-btn", visible: true)

      find(".search-clear-btn").click

      expect(find_field("q").value).to eq("")
    end
  end
end