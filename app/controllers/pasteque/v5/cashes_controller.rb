module Pasteque
  module V5
    class CashesController < Pasteque::V5::BaseController
      manage_restfully only: [:show, :update, :search],
                       model: :cash_session,
                       get_filters: { id: :id, cashRegisterId: :cash_id },
                       search_filters: {
                         cashRegisterId: :cash_id,
                         dateStart: :started_at,
                         dateStop: :stopped_at
                       }

      # From original code: inc/data/api/CashesAPI.php
      #
      # GET(cashRegisterId)
      # When client request a new cash, the server check for an active cash for
      # requested cash register. If found return it. Otherwise return NULL.
      #
      # GET(id)
      # Get cash by id, no matter it's state.
      def show
        if params[:cashRegisterId] && cash = Cash.find_by(id: params[:cashRegisterId])
          @record = cash.active_sessions.first
        elsif params[:id]
          @record = CashSession.find_by(id: params[:id])
        end
        if @record
          render locals: { resource: @record }
        else
          render json: { status: 'ok', content: nil }
        end
      end

      # From original code: inc/data/api/CashesAPI.php
      #
      # UPDATE(cash)
      # When client sends a cash, it may have an id or not. If the id is present the
      # cash is updated. If not a new cash is created. In all cases return the cash.
      def update
        raw_attributes = JSON.parse(params[:cash]).with_indifferent_access
        attributes = { cash_id: raw_attributes[:cashRegisterId] }
        attributes[:started_at] = Time.zone.at(raw_attributes[:openDate])
        attributes[:stopped_at] = Time.zone.at(raw_attributes[:closeDate])
        attributes[:noticed_start_amount] = raw_attributes[:openCash]
        attributes[:noticed_stop_amount]  = raw_attributes[:stopCash]
        attributes[:expected_stop_amount] = raw_attributes[:expectedCash]
        if raw_attributes[:id] && @record = CashSession.find_by(id: raw_attributes[:id])
          @record.update_attributes!(attributes)
        elsif cash = Cash.find_by(id: attributes[:cash_id])
          @record = cash.sessions.create!(attributes)
        else
          render json: { status: :rej, content: 'Cannot update cash' }
          return
        end
        render locals: { resource: @record }
      end

      def zticket
        @record = CashSession.find(params[:id]).zticket
        render partial: 'zticket', locals: { resource: @record }
      end
    end
  end
end
