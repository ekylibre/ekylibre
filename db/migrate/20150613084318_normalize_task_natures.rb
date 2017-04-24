class NormalizeTaskNatures < ActiveRecord::Migration
  CHANGES = {
    outgoing_email: :email,
    incoming_email: :email,
    outgoing_mail: :mail,
    incoming_mail: :mail,
    outgoing_call: :call,
    incoming_call: :call
  }.freeze
  def up
    execute 'UPDATE tasks SET nature = CASE ' + CHANGES.reject { |n, _o| n.to_s == ~ /^incoming\_/ }.map { |n, o| "WHEN nature = '#{o}' THEN '#{n}'" }.join(' ') + ' END WHERE nature IN (' + CHANGES.values.uniq.map { |x| "'#{x}'" }.join(', ') + ')'
    execute 'UPDATE tasks SET due_at = created_at WHERE due_at IS NULL'
    change_column_null :tasks, :due_at, false
  end

  def down
    change_column_null :tasks, :due_at, true
    execute 'UPDATE tasks SET nature = CASE ' + CHANGES.map { |n, o| "WHEN nature = '#{n}' THEN '#{o}'" }.join(' ') + ' END WHERE nature IN (' + CHANGES.keys.uniq.map { |x| "'#{x}'" }.join(', ') + ')'
  end
end
