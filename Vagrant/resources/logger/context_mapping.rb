def register(params)
    # @tools = params["tools"]
    @detected_tool = params["id_tool"]
    @detected_params = params["id_params"]
    @is_sudo = params["is_sudo"]
    @mitre = params["mitre_db"]
    @targets = params["targets"]
end

def filter(event)
    # If no command field, pass
    if event.get(@detected_tool).nil?
        return [event]
    end
    
    tool = event.get(@detected_tool)
    mapping = mitre_mapping(tool)
    

    # Adds Events
    event.set('MITRE_MAPPING', mapping)
    #event.set('target', target_machine)
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
