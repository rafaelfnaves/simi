require "rails_helper"

RSpec.describe "Dashboard" do
  it "sends an anonymous visitor to the sign in page" do
    get root_path

    expect(response).to redirect_to(new_session_path)
  end

  it "shows the dashboard to a signed in user" do
    sign_in create(:user)

    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Dashboard")
  end
end
