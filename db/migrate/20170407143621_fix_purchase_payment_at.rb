# coding: utf-8

class FixPurchasePaymentAt < ActiveRecord::Migration
  def change
    reversible do |d|
      d.up do
        execute <<-SQL.strip_heredoc
          CREATE FUNCTION compute_delay(start TIMESTAMP, delay VARCHAR)
          RETURNS TIMESTAMP AS $$
          DECLARE
            d TIMESTAMP;
            step VARCHAR;
            period VARCHAR;
            count INTEGER;
            direction INTEGER;
          BEGIN
            d := start;
            FOR step IN SELECT regexp_split_to_table(delay, '\\s*,\\s*') LOOP
              IF step ~* '^(eom|end of month|fdm|fin de mois)$' THEN
                d := date_trunc('month', d) + '1 month'::INTERVAL - '1 day'::INTERVAL;
              ELSIF step ~* '^(bom|beginning of month|ddm|debut de mois|début de mois)$' THEN
                d := date_trunc('month', d);
              ELSIF step ~* '^\\d+\\ (\\w+)(\\ (avant|ago))?$' THEN
                direction = CASE WHEN LENGTH(TRIM(split_part(step, ' ', 3))) > 0 THEN -1 ELSE 1 END;
                period = split_part(step, ' ', 2);
                count = split_part(step, ' ', 1)::INTEGER;
                IF period ~* '^(an|année|annee|year)s?$' THEN
                  d := d + ((direction * count)::VARCHAR || ' years')::INTERVAL;
                ELSIF period ~* '^(mois|month|months)$' THEN
                  d := d + ((direction * count)::VARCHAR || ' months')::INTERVAL;
                ELSIF period ~* '^(week|semaine)s?$' THEN
                  d := d + ((direction * count * 7)::VARCHAR || ' days')::INTERVAL;
                ELSIF period ~* '^(day|jour)s?$' THEN
                  d := d + ((direction * count)::VARCHAR || ' days')::INTERVAL;
                ELSIF period ~* '^(hour|heure)s?$' THEN
                  d := d + ((direction * count)::VARCHAR || ' hours')::INTERVAL;
                ELSIF period ~* '^minutes?$' THEN
                  d := d + ((direction * count)::VARCHAR || ' minutes')::INTERVAL;
                ELSIF period ~* '^seconde?s?$' THEN
                  d := d + ((direction * count)::VARCHAR || ' seconds')::INTERVAL;
                END IF;
              END IF;
            END LOOP;
            RETURN d;
          END;
          $$ LANGUAGE plpgsql
SQL

        execute 'UPDATE purchases SET payment_at = compute_delay(COALESCE(invoiced_at, planned_at), payment_delay) WHERE LENGTH(TRIM(payment_delay)) > 0 AND (invoiced_at IS NOT NULL OR planned_at IS NOT NULL)'
        execute 'UPDATE purchases SET payment_at = COALESCE(invoiced_at, planned_at) WHERE LENGTH(TRIM(payment_delay)) = 0 AND (invoiced_at IS NOT NULL OR planned_at IS NOT NULL)'
        execute 'DROP FUNCTION compute_delay(TIMESTAMP, VARCHAR);'
      end
    end
  end
end
