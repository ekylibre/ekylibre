module Printers
  class WorkerRegisterPrinter < PrinterBase
    class << self
      # TODO move this elsewhere when refactoring the Document Management System
      def build_key(campaign:)
        campaign.name
      end
    end

    attr_accessor :campaign

    def initialize(template:, campaign:)
      super(template: template)

      @campaign = campaign
    end

    def key
      self.class.build_key campaign: campaign
    end

    def build_intervention_dataset(intervention, worker)
      duration = compute_duration(intervention, worker)
      raw_number_of_days = (intervention.stopped_at - intervention.started_at).in(:second).in(:day).to_f
      number_of_days = raw_number_of_days < 1 ? raw_number_of_days.ceil : raw_number_of_days.to_i
      {
        day: I18n.l(intervention.started_at, format: '%A')[0..2] + '.',
        started_at: I18n.l(intervention.started_at, format: '%d/%m/%y'),
        stopped_at: I18n.l(intervention.stopped_at, format: '%d/%m/%y'),
        duration: duration.in(:second).in(:hour).to_f.round(2),
        number_of_days: number_of_days,
        balance: ((duration.to_f / 3600) - 7.to_f).round(2),
        intervention_name: intervention.event.name
      }
    end

    def compute_duration(intervention, worker)
      if intervention.participations.of_product(worker.id).any?
        intervention.worker_working_periods(worker_id: worker.id).map(&:duration).compact.sum
      else
        intervention.working_duration
      end
    end

    def compute_dataset
      data = Intervention.real.of_civil_year(campaign.harvest_year).flat_map do |inter|
        inter.doers.map do |doer|
          { worker: doer.product, intervention: inter }
        end
      end.group_by { |element| element[:worker] }

      dataset = data.flat_map do |w, w_inters|
        w_inters.map { |element| element[:intervention] }
                .group_by { |inter| inter.started_at.to_date.beginning_of_month }
                .map { |date, interventions| { worker: w, date: date, interventions: interventions } }
      end

      dataset = dataset.map { |item| { **item, header_dataset: [{ name: item[:worker].name, date: item[:date] }] } }
                       .sort_by { |item| [item[:worker].person.last_name.upcase, item[:date]] }
                       .map do |item|
                         total_duration = item[:interventions].map { |intervention| compute_duration(intervention, item[:worker]) }.sum.in(:second).in(:hour).to_f.round(2)
                         intervention_dataset = item[:interventions].map do |intervention|
                           build_intervention_dataset(intervention, item[:worker])
                         end
                         {
                           **item,
                           interventions_dataset: intervention_dataset.sort_by { |int| int[:started_at] },
                           total_duration: total_duration,
                           total_balance: total_duration - 150.to_f
                         }
                       end
      worker_register = Worker.all.map do |worker|
        { worker: worker, worked: data.keys.include?(worker) }
      end

      worker_register = worker_register.map { |hash| { **hash, full_name: "#{hash[:worker].person.last_name.upcase} #{hash[:worker].person.first_name}" } }
                                       .sort_by { |e| e[:full_name] }
      one, two, three = worker_register.in_groups(3)
      zipped_wr = one.zip(two, three)

      [zipped_wr, dataset]
    end

    def run_pdf
      worker_register, dataset = compute_dataset
      # Company
      company = EntityDecorator.decorate(Entity.of_company)

      generate_report(template_path) do |r|
        # First page Company
        r.add_field :company_name, company.name
        r.add_field :company_address, company.inline_address

        # Campaign name
        r.add_field :campaign_name, campaign.name

        # Worker register
        r.add_table('Table-workers-register', worker_register) do |tw|
          tw.add_field(:col_1) { |item| Maybe(item)[0][:full_name].or_else("") }
          tw.add_field(:col_2) { |item| Maybe(item)[1][:full_name].or_else("") }
          tw.add_field(:col_3) { |item| Maybe(item)[2][:full_name].or_else("") }
          tw.add_field(:mark_1) { |item| Maybe(item)[0][:worked].or_else(false) ? 'X' : '' }
          tw.add_field(:mark_2) { |item| Maybe(item)[1][:worked].or_else(false) ? 'X' : '' }
          tw.add_field(:mark_3) { |item| Maybe(item)[2][:worked].or_else(false) ? 'X' : '' }
        end

        # Section-workers
        r.add_section('Section-workers', dataset) do |w|
          # Header
          w.add_table('Table-worker-header', :header_dataset) do |wh|
            wh.add_field(:worker_name) { |item| item[:name] }
            wh.add_field(:month) { |item| I18n.l(item[:date], format: :month_name).capitalize }
          end

          # Table-worker
          w.add_table('Table-worker', :interventions_dataset) do |i|
            # Day
            i.add_field(:day) { |item| item[:day] }

            # Started_at
            i.add_field(:started_at) { |item| item[:started_at] }

            # Stopped_at
            i.add_field(:stopped_at) { |item| item[:stopped_at] }

            # Duration
            i.add_field(:duration) { |item| item[:duration] }

            # Number of days
            i.add_field(:number_of_days) { |item| item[:number_of_days] }

            # Balance
            i.add_field(:balance) { |item| item[:balance] }

            # Intervention name
            i.add_field(:intervention_name) { |item| item[:intervention_name] }
          end

          # Table totals
          w.add_field :total_duration, :total_duration

          # Total balance
          w.add_field :total_balance, :total_balance
        end

        # Footer date
        r.add_field :date, Time.zone.now.l

        # Footer
        r.add_field :campaign_year, campaign.name
      end
    end
  end
end
