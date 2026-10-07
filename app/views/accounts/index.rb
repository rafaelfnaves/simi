# frozen_string_literal: true

class Views::Accounts::Index < Views::Base
  include Phlex::Rails::Helpers::ButtonTo

  def initialize(accounts:)
    @accounts = accounts
  end

  def view_template
    render Components::PageHeader.new(title: t(".title"), subtitle: t(".subtitle")) do
      RubyUI.Button(as: :a, href: new_account_path) { t(".new") }
    end

    @accounts.any? ? table : empty_state
  end

  private

  def empty_state
    RubyUI.Card(class: "p-6") do
      RubyUI.Empty do
        RubyUI.EmptyHeader do
          RubyUI.EmptyTitle { t(".empty_title") }
          RubyUI.EmptyDescription { t(".empty_description") }
        end
        RubyUI.EmptyContent do
          RubyUI.Button(as: :a, href: new_account_path) { t(".empty_action") }
        end
      end
    end
  end

  def table
    RubyUI.Card(class: "overflow-x-auto") do
      RubyUI.Table do
        RubyUI.TableHeader do
          RubyUI.TableRow do
            RubyUI.TableHead { t(".columns.name") }
            RubyUI.TableHead { t(".columns.kind") }
            RubyUI.TableHead { t(".columns.institution") }
            RubyUI.TableHead(class: "text-right") { t(".columns.balance") }
            RubyUI.TableHead(class: "text-right") { t(".columns.actions") }
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
          RubyUI.Badge(variant: :outline) { t(".archived") } if account.archived?
        end
      end
      RubyUI.TableCell { account.human_kind }
      RubyUI.TableCell { account.institution || t(".blank") }
      RubyUI.TableCell(class: "text-right tabular-nums") do
        render Components::Money.new(account.balance, tone: :signed)
      end
      RubyUI.TableCell(class: "text-right") { actions(account) }
    end
  end

  def actions(account)
    div(class: "flex flex-wrap items-center justify-end gap-x-3 gap-y-1") do
      RubyUI.Link(href: edit_account_path(account)) { t("actions.edit") }

      if account.archived?
        button_to t("actions.unarchive"), account_archive_path(account), method: :delete, class: link_classes
      else
        button_to t("actions.archive"), account_archive_path(account), class: link_classes
      end

      button_to t("actions.delete"), account_path(account), method: :delete, class: link_classes,
        form: { data: { turbo_confirm: t("confirm.delete", name: account.name) } }
    end
  end

  def link_classes = "text-sm underline underline-offset-4 hover:text-primary"
end
