class EkyTreeContext < TreeContext
  def nest
    @depth += 1
    yield
  ensure
    @depth -= 1
  end
end

class MenuGroup
  attr_reader :name, :subgroups

  def initialize(name, subgroups: {})
    @name = name
    @subgroups = subgroups
  end

  def contains?(item)
    raise NotImplementedError
  end
end

class RegexGroup < MenuGroup
  attr_reader :regex

  def initialize(name, regex, subgroups: {})
    super(name, subgroups: subgroups)

    @regex = regex
  end

  def contains?(item)
    item && item.files.map(&:first).any? { |f| f =~ regex }
  end
end

# @return [String] HTML output of the classes to be displayed in the
#    full_list_class template.
def class_list(root = Registry.root, tree = EkyTreeContext.new)
  children = run_verifier(root.children)

  children += @items.select { |o| o.namespace.is_a?(CodeObjects::Proxy) }
  groups = [
    RegexGroup.new('App', Regexp.new("\\Aapp/.*\\z"), subgroups: make_rails_groups(make_rails_subgroups)),
    RegexGroup.new('Lib', Regexp.new("\\Alib/.*\\z"))
  ]

  render_groups(grouped(children, groups), tree)
end

def render_groups(groups, tree)
  groups_code = groups.reject { |k, _v| k == :std }
                      .sort_by { |k, _v| k.name }
                      .map { |group, items| [group, render_group(group, tree) { |subgroups| render_collection(items, tree, subgroups) }] }
                      .to_h
  items_code = render_items(groups.fetch(:std, []), tree)

  groups_code.merge(items_code)
             .sort { |(a, _code_a), (b, _code_b)| item_comparator(a, b) }
             .map { |(_key, value)| value }
             .join
end

def render_group(group, tree)
  <<~HTML
    <li class="#{tree.classes.join(' ')} nolink">
      <div class="item" style="padding-left:#{tree.indent}">
        <a class='toggle'></a> #{group.name}
      </div>
      #{yield(group.subgroups)}
    </li>
  HTML
end

def render_item(item, tree)
  <<~HTML
    <li id="object_#{item.path}" class="#{tree.classes.join(' ')}">
      <div class="item" style="padding-left:#{tree.indent}">
        #{render_item_label(item)}
      <small class="search_info">
        #{item.namespace.title}
      </small>
      </div>
      #{render_children(item, tree)}
    </li>
  HTML
end

def render_item_label(item)
  name = item.namespace.is_a?(CodeObjects::Proxy) ? item.path : item.name
  has_children = item.is_a?(CodeObjects::NamespaceObject) && run_verifier(item.children).any? { |o| o.is_a?(CodeObjects::NamespaceObject) }

  html = ""
  html << "<a class='toggle'></a> " if has_children
  html << linkify(item, name)
  html << " &lt; #{item.superclass.name}" if item.is_a?(CodeObjects::ClassObject) && item.superclass

  html
end

def render_children(item, tree)
  render_collection(run_verifier(item.children).select { |i| i&.is_a? CodeObjects::NamespaceObject }.sort_by(&:name), tree)
end

def render_items(items, tree)
  items.map { |e| [e, render_item(e, tree)] }
       .to_h
end

def item_comparator(a, b)
  ansp = a.is_a?(MenuGroup) || a.children.any? { |c| c.is_a?(CodeObjects::NamespaceObject) }
  bnsp = b.is_a?(MenuGroup) || b.children.any? { |c| c.is_a?(CodeObjects::NamespaceObject) }

  if ansp & !bnsp
    -1
  elsif !ansp && bnsp
    1
  else
    a.name <=> b.name
  end
end

def render_collection(items, tree, groups = [])
  g = grouped(items, groups)
  if g.any?
    <<~HTML
      <ul>
        #{tree.nest { render_groups(g, tree) }}
      </ul>
    HTML
  else
    ''
  end
end

def make_rails_groups(subgroups = {})
  RAILS_GROUPS_IDS.map do |id|
    RegexGroup.new(id.capitalize.to_sym, Regexp.new("\\Aapp/#{id}/.*\\z"), subgroups: subgroups)
  end
end

def make_rails_subgroups
  RAILS_SUBGROUPS_IDS.map do |id|
    RegexGroup.new(id.capitalize.to_sym, Regexp.new("\\Aapp/[a-z_]+/#{id}/.*\\z"))
  end
end

RAILS_GROUPS_IDS = %w[concepts controllers decorators exchangers helpers inputs integrations interactors jobs mailers models queries services validators]
RAILS_SUBGROUPS_IDS = %w[concerns bookkeepers]

def grouped(children, groups)
  children.compact
          .reject { |c| c.type == :method }
          .group_by { |child| groups.detect { |v| v.contains?(child) } || :std }
          .map { |k, e| [k, e.sort_by(&:path)] } #TODO use transform_values when ruby2.6 is here
          .to_h
end

