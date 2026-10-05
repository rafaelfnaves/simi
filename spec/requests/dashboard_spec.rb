require "rails_helper"

RSpec.describe "Dashboard" do
  it "sends an anonymous visitor to the sign in page" do
    get root_path

    expect(response).to redirect_to(new_session_path)
  end

  describe "the consolidated balance" do
    let(:user) { create(:user) }

    def consolidated_card
      body = Nokogiri::HTML5(response.body)
      body.css("span").find { |node| node.text == "Saldo consolidado" }.parent
    end

    before { sign_in user }

    it "sums the accounts that hold money" do
      create(:checking_account, user:, balance: "1.000,00")
      create(:wallet_account, user:, balance: "234,56")

      get root_path

      expect(consolidated_card.text).to include("1.234,56")
    end

    it "leaves the archived ones out of the sum" do
      create(:checking_account, user:, balance: "1.000,00")
      create(:wallet_account, :archived, user:, balance: "500,00")

      get root_path

      expect(consolidated_card.text).to include("1.000,00")
      expect(consolidated_card.text).not_to include("1.500,00")
    end

    it "keeps the empty state while no account holds money, instead of showing zero" do
      get root_path

      expect(consolidated_card.text).to include("Cadastre suas contas")
      expect(consolidated_card.text).not_to include("R$")
    end

    it "goes back to the empty state when every account is archived" do
      create(:checking_account, :archived, user:, balance: "1.000,00")

      get root_path

      expect(consolidated_card.text).to include("Cadastre suas contas")
    end

    it "marks a negative consolidated balance" do
      create(:checking_account, user:, balance: "-90,00")

      get root_path

      expect(consolidated_card.to_html).to include("text-destructive")
      expect(consolidated_card.text).to include("90,00")
    end

    it "never counts someone else's accounts" do
      create(:checking_account, balance: "9.999,00")

      get root_path

      expect(consolidated_card.text).not_to include("9.999,00")
    end
  end

  context "when signed in" do
    before { sign_in create(:user, name: "Maria Silva") }

    it "shows every block the product promises" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        "Saldo consolidado", "Receitas do mês", "Despesas do mês",
        "Gastos por categoria", "Despesas por projeto",
        "Evolução mensal", "Últimas movimentações"
      )
    end

    it "shows zeroed metrics rather than invented numbers for the blocks still to come" do
      get root_path

      expect(response.body).to include("R$ 0,00")
    end

    it "explains each empty block instead of leaving it blank" do
      get root_path
      body = Nokogiri::HTML5(response.body)

      expect(body.text).to include(
        "Quando houver despesas categorizadas",
        "Agrupe gastos de uma viagem ou reforma",
        "Importe um extrato ou registre um lançamento"
      )
    end

    it "identifies the signed in person and offers a way out" do
      get root_path

      expect(response.body).to include("Maria Silva")
      expect(response.body).to include("Sair")
    end

    it "offers the theme switch from the topbar" do
      get root_path
      body = Nokogiri::HTML5(response.body)

      expect(body.at_css("form[action='/settings/theme']")).to be_present
      expect(body.at_css("[aria-label='Alternar tema']")).to be_present
    end

    it "offers the navigation to every area" do
      get root_path

      expect(response.body).to include("Transações", "Contas", "Cartões", "Categorias")
    end
  end
end
