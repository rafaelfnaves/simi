# frozen_string_literal: true

class Views::Accounts::Index < Views::Base
  include Phlex::Rails::Helpers::ButtonTo

  def initialize(accounts:)
    @accounts = accounts
  end

  def view_template
    render Components::PageHeader.new(
      title: "Contas",
      subtitle: "Onde o seu dinheiro está."
    ) { RubyUI.Button(as: :a, href: new_account_path) { "Nova conta" } }

    @accounts.any? ? table : empty_state
  end

  private

  def empty_state
    RubyUI.Card(class: "p-6") do
      RubyUI.Empty do
        RubyUI.EmptyHeader do
          RubyUI.EmptyTitle { "Nenhuma conta cadastrada" }
          RubyUI.EmptyDescription do
            plain "Uma conta é um lugar onde o seu dinheiro está: um banco, uma poupança, " \
                  "uma carteira digital ou o dinheiro em espécie. Cadastre a primeira para " \
                  "começar a acompanhar o saldo."
          end
        end
        RubyUI.EmptyContent do
          RubyUI.Button(as: :a, href: new_account_path) { "Cadastrar conta" }
        end
      end
    end
  end

  def table
    RubyUI.Card(class: "overflow-x-auto") do
      RubyUI.Table do
        RubyUI.TableHeader do
          RubyUI.TableRow do
            RubyUI.TableHead { "Conta" }
            RubyUI.TableHead { "Tipo" }
            RubyUI.TableHead { "Instituição" }
            RubyUI.TableHead(class: "text-right") { "Saldo" }
            RubyUI.TableHead(class: "text-right") { "Ações" }
          end
        end

        RubyUI.TableBody do
          @accounts.each { |account| row(account) }
        end
      end
    end
  end

  def row(account)
    RubyUI.TableRow do
      RubyUI.TableCell(class: "font-medium") do
        div(class: "flex items-center gap-2") do
          span(class: ("text-muted-foreground" if account.archived?)) { account.name }
          RubyUI.Badge(variant: :outline) { "Arquivada" } if account.archived?
        end
      end
      RubyUI.TableCell { Account::KIND_LABELS.fetch(account.kind) }
      RubyUI.TableCell { account.institution || "—" }
      RubyUI.TableCell(class: "text-right tabular-nums") do
        render Components::Money.new(account.balance, tone: :signed)
      end
      RubyUI.TableCell(class: "text-right") { actions(account) }
    end
  end

  def actions(account)
    div(class: "flex flex-wrap items-center justify-end gap-x-3 gap-y-1") do
      RubyUI.Link(href: edit_account_path(account)) { "Editar" }

      if account.archived?
        button_to "Reativar", account_archive_path(account), method: :delete, class: link_classes
      else
        button_to "Arquivar", account_archive_path(account), class: link_classes
      end

      button_to "Excluir", account_path(account), method: :delete, class: link_classes,
        form: { data: { turbo_confirm: "Excluir #{account.name}? Isso não pode ser desfeito." } }
    end
  end

  def link_classes = "text-sm underline underline-offset-4 hover:text-primary"
end
