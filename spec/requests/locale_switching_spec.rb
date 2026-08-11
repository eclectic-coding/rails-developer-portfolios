require 'rails_helper'

RSpec.describe "Locale switching", type: :request do
  it "renders Spanish when Accept-Language prefers es" do
    get '/', headers: { 'Accept-Language' => 'es-ES,es;q=0.9' }
    expect(response.body).to include('Portafolios de Desarrolladores')
    expect(response.body).to match(/<html lang="es"/)
  end

  it "renders English by default" do
    get '/', headers: { 'Accept-Language' => 'en-US,en;q=0.9' }
    expect(response.body).to include('Developer Portfolios')
    expect(response.body).to match(/<html lang="en"/)
  end

  it "falls back to English for unsupported locales" do
    get '/', headers: { 'Accept-Language' => 'fr-FR,fr;q=0.9' }
    expect(response.body).to include('Developer Portfolios')
  end

  it "does not leak locale across requests" do
    get '/', headers: { 'Accept-Language' => 'es-ES,es;q=0.9' }
    expect(I18n.locale).to eq(:en)
  end
end
