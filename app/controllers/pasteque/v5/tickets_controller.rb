module Pasteque
  module V5
    class TicketsController < Pasteque::V5::BaseController
      search_filters = {
        ticketId: :id,
        cashId: :cash_session_id,
        dateStart: :created_at,
        dateStop: :closed_on,
        customerId: :third_id,
        userId: :originator_id
      }
      update_filters = {
        id: :id,
        date: :started_at,
        cashId: :cash_id,
        ticketId: :affair_id,
        userId: :user_id,
        customerId: :customer_id,
        type: :nature,
        custCount: :count,
        tariffAreaId: :catalog_id,
        payments: :incoming_payments,
        lines: :affairs
      }
      manage_restfully except: [:new, :edit], model: :sale_ticket, search_filters: search_filters, update_filters: update_filters

      def open
        @records = model.tickets.openeds
        render 'index'
      end

      # Save tickets
      def save
        tickets = []
        if params[:ticket]
          tickets << JSON.parse(params[:ticket]).with_indifferent_access
        else
          tickets += JSON.parse(params[:tickets]).map(&:with_indifferent_access)
        end
        unless cash = Cash.find_by(id: params[:cashId])
          render json: { status: :rej, content: 'Cannot find cash' }
          return
        end
        saved = []
        tickets.each do |ticket_params|
          third = nil
          if ticket_params[:customerId]
            third = Entity.find_by(id: ticket_params[:customerId])
          end
          unless ticket = SaleTicket.find_by(id: ticket_params[:id])

            ticket = SaleTicket.build(third: third)
          end
          # TODO

          if ticket.save
            saved << ticket
          else
            puts ticket.errors.full_messages.to_sentence.yellow
          end
        end
        render json: { status: :ok, content: saved.count }
      end

      protected

      def permitted_params
        params.require(:ticket).permit!
      end
    end
  end
end
