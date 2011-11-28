module Prawn
  class PatientLetter < Prawn::LetterDocument
    include InvoicesHelper
    include I18nRailsHelpers
    include EsrRecipe

    # Helpers
    def h(s)
      return s
    end

    def initialize_fonts
      # Fonts
      font_path = '/usr/share/fonts/truetype/ttf-dejavu/'
      font_families.update(
        "DejaVuSans" => { :bold        => font_path + "DejaVuSans-Bold.ttf",
                          :normal      => font_path + "DejaVuSans.ttf" }
      )

      font 'DejaVuSans'
    end

    # Title
    def title(invoice)
      font_size 16
      text "Patientenrechnung Nr. #{invoice.id}", :style => :bold
      font_size 6.5
      text "Diese Seite ist für Ihre Unterlagen, der beilegende Rückforderungsbeleg für Ihre Krankenkasse."
    end

    # Biller / Provider
    def biller(invoice)
      font_size 6.5
      text "Rechnungssteller/Leistungserbringer:"
      font_size 8
      draw_address(invoice.biller.vcard)
      for contact in invoice.biller.vcard.contacts
        text contact.to_s
      end
      text " "
      font_size 6.5
      text "Rechnungs-Datum:"
      font_size 8
      text invoice.value_date.to_s
    end

    # Referrer
    def referrer(invoice)
      font_size 6.5
      text "Zuweisender Arzt:"
      font_size 8
      draw_address(invoice.referrer.vcard) if invoice.referrer
      text " "
      font_size 6.5
      text "Behandlung vom:"
      font_size 8
      text invoice.treatment.date_begin.to_s
    end

    # Billing Address
    def billing_address(invoice)
      font_size 10
      text invoice.patient.billing_vcard.honorific_prefix if invoice.patient.billing_vcard.honorific_prefix
      draw_address(invoice.patient.billing_vcard)
    end

    # Patient
    def patient(invoice)
      font_size 6.5
      text "Patient:"
      font_size 8
      draw_address(invoice.patient.vcard)
      text " "
      font_size 6.5
      text "Geburtsdatum:"
      font_size 8
      text invoice.patient.birth_date.to_s
    end

    # Balance
    def balance(invoice)
      font_size 6.5
      text "Kontoauszug:"
      font_size 8
      content = invoice.bookings.map{|booking|
        [
          booking.value_date,
          booking.title + (booking.comments.present? ? "\n<font size='6.5'>#{booking.comments}</font>" : ""),
          sprintf("%0.2f CHF", booking.accounted_amount(Invoice::DEBIT_ACCOUNT))
        ]
      }
      content << [
        nil,
        invoice.due_amount.currency_round >= 0 ? I18n::translate(:open_amount, Invoice, :scope => "activerecord.attributes.invoice") : I18n::translate(:balance, Invoice, :scope => "activerecord.attributes.invoice"),
        sprintf("%0.2f CHF", invoice.due_amount.currency_round)
      ]

      table content, :width => 13.cm, :cell_style => {:inline_format => true} do
        # General
        cells.borders = []
        cells.padding = [0.5, 2, 0.5, 2]

        # With
        column(0).width = 3.cm
        column(1).width = 8.cm
        column(2).width = 2.cm

        # Alignment
        column(2).align = :right

        # Total
        row(-1).borders    = [:top]
        row(-1).font_style = :bold
      end
    end

    def to_pdf(invoice)
      bounding_box [1.cm, bounds.top], :width => bounds.width do
        title(invoice)

        # Head info
        bounding_box [0, bounds.top - 2.4.cm], :width => 7.cm do
          biller(invoice)
        end

        bounding_box [0, bounds.top - 8.cm], :width => 7.cm do
          referrer(invoice)
        end

        bounding_box [12.cm, bounds.top - 3.5.cm], :width => 7.cm do
          billing_address(invoice)
        end

        bounding_box [12.cm, bounds.top - 8.cm], :width => 7.cm do
          patient(invoice)
        end

        # Invoice balance
        bounding_box [0, bounds.top - 13.cm], :width => 7.cm do
          balance(invoice)
        end
      end

      # VESR form
      draw_esr(invoice, invoice.biller.esr_account, invoice.biller, invoice.biller.use_vesr)

      render
    end
  end
end