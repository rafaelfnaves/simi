class ApplicationMailer < ActionMailer::Base
  default from: "SIMI <nao-responda@simi.app>"
  layout "mailer"

  private
    # Bodies are Phlex classes rather than templates (constitution principle II),
    # and Phlex renders HTML only, so the plain text alternative is passed in as
    # a string instead of being dropped.
    #
    # @param html [Phlex::HTML]
    # @param text [String]
    def mail_with(html:, text:, **options)
      mail(**options) do |format|
        format.text { render plain: text }
        format.html { render html }
      end
    end
end
