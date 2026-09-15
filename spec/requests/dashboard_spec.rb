require "rails_helper"

RSpec.describe "Dashboard" do
  it "sends an anonymous visitor to the sign in page" do
    get root_path

    expect(response).to redirect_to(new_session_path)
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

    it "shows zeroed metrics rather than invented numbers" do
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

    it "offers the navigation to every area" do
      get root_path

      expect(response.body).to include("Transações", "Contas", "Cartões", "Categorias")
    end
  end
end
