def register(params)
    @command = params["command"]
    @tools = params["tools"]
end

def filter(event)
    # If no command field, pass
    if event.get(@command).nil?
        return [event]
    end
    
    # Split out the command into an array
    split_cmd = event.get(@command).split(" ")

    #event.set('split_cmd', split_cmd)

    # Checks for tool used
    tool, priv = tool_check(split_cmd[0,2])

    # If tool is not to be enumerated, pass
    # unless @tools.include? tool 
    #     return [event]
    # end

    # Returns all parameters used
    if priv
        tool_params, non_param = param_check(split_cmd[2..-1])
    else
        tool_params, non_param = param_check(split_cmd[1..-1])
    end

    # Adds Events
    event.set('IS_SUDO', priv)
    event.set('PARSED_TOOL', tool)
    event.set('PARSED_TOOL_PARAMETERS', tool_params)
    event.set('PARSED_TOOL_NON_PARAMETERS', non_param)
    # event.set('PARSED_TOOL_FULL_PARAMETERS', tool_full_param)
    return [event]
end

def tool_check(cmd)
    if cmd[0].casecmp("sudo") == 0
        return cmd[1], true
    else
        return cmd[0], false
    end
end

def param_check(cmd)
    param = []
    #full_param = []
    non_param = []
    # temp = ""
    cmd.each do |i|
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
