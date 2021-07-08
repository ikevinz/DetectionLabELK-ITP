def register(params)
    # @tools = params["tools"]
    @keystrokes = params["keystrokes"]
end

def filter(event)
    # If no message field, pass
    if event.get(@keystrokes).nil?
        return [event]
    end

    split_keystroke = event.get(@keystrokes).split(" ")

    priv = is_sudo(split_keystroke)
    event.set('IS_SUDO', priv)

    tools = tool_check(split_keystroke)
    event.set('PARSED_TOOL', tools)

    tool_params, non_param = param_check(split_keystroke)
    event.set('PARSED_TOOL_PARAMETERS', tool_params)
    event.set('PARSED_TOOL_NON_PARAMETERS', non_param)

    mapping = mitre_mapping(split_keystroke)
    event.set('MITRE_MAPPING', mapping)

    targets, filepaths = target_path_mapping(split_keystroke)
    event.set('TARGETED_MACHINES', targets)
    event.set('TARGETED_FILEPATHS', filepaths)

    return [event]
end

def mitre_mapping(ks)
    require 'json'

    if ks.empty?
        return "None"
    else
        mitre_mappings = []
        mitre_db = JSON.parse(File.read('/etc/logstash/rb/db/keylogger_hash.json'))
        mitre_db.each do |key, value|
            # if value.include? ks
            #     mitre_mappings << key 
            # end
            unless value & ks.empty?
                mitre_mappings << key
            end
        end
        if mitre_mappings.empty?
            mitre_mappings << "None"
        end
        return mitre_mappings
    end
end

def target_path_mapping(ks)
    require 'json'

    if ks.empty?
        return "None", "None"
    else
        # target_mappings = []
        # filepaths = []

        target_db = JSON.parse(File.read('/etc/logstash/rb/db/targets.json'))
        
        # Checks for filepaths and scanned ips
        target_mappings = ks.select {|i| i =~ /\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/}
        filepaths = ks.select {|i| i=~ /(\/\S*)/}
        # i =~ "/^([a-zA-Z]):[\\\/]((?:[^<>:"\\\/\|\?\*]+[\\\/])*)([^<>:"\\\/\|\?\*]+)\.([^<>:"\\\/\|\?\*\s]+)$/gm" or

        # Check if known machines are targeted
        # target_db.each do |key, value|
        #     # If matches a host machine
        #     if ks.include? key
        #         target_mappings << value 
        #     end
        # end

        # If no targets present
        if target_mappings.empty?
            target_mappings << "None"
        end
        # If no filepaths present
        if filepaths.empty?
            filepaths << "None"
        end
        
        return target_mappings, filepaths
    end
end

def is_sudo(ks)
    if ks.empty?
        return false
    else
        return ks.any?{ |s| s.casecmp("sudo")==0 }
    end
end

def param_check(ks)
    if ks.empty?
        return "None", "None"
    else
        param = []
        #full_param = []
        non_param = []
        # temp = ""
        ks.each do |i|
            if i[0] == "-" or i[0,2] == "--"
                param << i
                # if temp.nil? 
                #     temp = i
                # else
                #     full_param << temp
                #     temp = i
                # end
            else
                non_param << i
                # temp << " #{i}"
            end
        end 
        return param, non_param
    end
end

def tool_check(ks)
    require 'json'

    if ks[0].casecmp("sudo") == 0
        return cmd[1]
    else
        tool_db = JSON.parse(File.read('/etc/logstash/rb/db/tool_array.json'))
        tools = ks.select {|i| tool_db.include? i}
        return tools
    end
end