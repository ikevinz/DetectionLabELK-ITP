def register(params)
    # @tools = params["tools"]
    @keystrokes = params["keystrokes"]
end

def filter(event)
    # If no message field, pass
    if event.get(@message).nil?
        return [event]
    end

    split_keystroke = event.get(@keystrokes)

    mapping, tool = mitre_mapping(split_keystroke)
    target = target identification(split_keystroke)
    

    # Adds Events
    event.set('MITRE_MAPPING', mapping)
    event.set('POSSIBLE_TOOL', tool)
    event.set('TARGETED_MACHINE', target)
    return [event]
end

def mitre_mapping(tool)
    mitre_mappings = []
    @mitre.each do |key, value|
        if value.include? tool
            mitre_mappings << key 
        end
    end
    return mitre_mappings
end
