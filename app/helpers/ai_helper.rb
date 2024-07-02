module AiHelper
  INSTRUCTIONS_INDEX = Rails.root.join('db', 'nomenclatures', 'ai_context.yml').freeze
  INSTRUCTIONS = (INSTRUCTIONS_INDEX.exist? ? YAML.load_file(INSTRUCTIONS_INDEX) : {}).freeze

  def item_ai_instruction(nature)
    instruction = INSTRUCTIONS[nature.to_s]
    return nil unless instruction

    instruction['instructions']
  end

  def item_ai_output_schema(nature)
    instruction = INSTRUCTIONS[nature.to_s]
    return nil unless instruction

    if instruction['output_schema'].present?
      instruction['output_schema'].to_json
    else
      nil
    end
  end
end
