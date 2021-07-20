def register(params)
    # @tools = params["tools"]
    @detected_tool = params["id_tool"]
    @detected_params = params["id_params"]
    @detected_nonparams = params["id_nonparams"]
    @is_sudo = params["is_sudo"]
    @user = params["user"]
    # @mitre = params["mitre_db"]
    # @targets = params["targets"]
end

def filter(event)
    # If no command field, pass
    if event.get(@detected_tool).nil?
        return [event]
    end
    
    # mapping tool used to MITRE
    tool = event.get(@detected_tool)
    mi_tools, tactics, techniques, techniquesid = mitre_mapping(tool)
    event.set('MITRE_SOFTWARE', mi_tools)
    event.set('MITRE_TECHNIQUES', techniques)
    event.set('MITRE_TECHNIQUESID', techniquesid)
    event.set('MITRE_TACTICS', tactics)
    
    # Mapping targets
    targets = []
    filepaths = []
    unless event.get(@detected_nonparams).empty?
        targets, filepaths = target_path_mapping(event.get(@detected_nonparams))
    end
    if targets.empty?
        targets << "None"
    end
    if filepaths.empty?
        filepaths << "None"
    end
    event.set('TARGETED_MACHINES', targets)
    event.set('TARGETED_FILEPATHS', filepaths)    
    
    return [event]
end

def mitre_mapping(tool)
    require 'json'

    mitre_tools = []
    mitre_tactics = []
    mitre_techniques = []
    mitre_techniquesid = []

    mitre_db = JSON.parse(File.read('/etc/logstash/rb/db/MITRE_SOFTWARE.json'))

    if mitre_db.key?(tool)
        mitre_tools |= tool
        mitre_tactics |= mitre_db[tool]["tactics"]
        mitre_techniques |= mitre_db[tool]["techniques"]
        mitre_techniquesid |= mitre_db[tool]["techniques_id"]

        return mitre_tools, mitre_tactics, mitre_techniques, mitre_techniquesid
    else
        return "None", "None", "None", "None"
    end    
end

def target_path_mapping(nonparams)
    require 'json'

    if nonparams.empty?
        return "None"
    else
        # target_mappings = []
        # filepaths = []

        target_db = JSON.parse(File.read('/etc/logstash/rb/db/targets.json'))
        
        # Checks for filepaths and scanned ips
        target_mappings = nonparams.select {|i| i =~ /\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/}
        filepaths = nonparams.select {|i| i=~ /(\/\S*)/}
        # i =~ "/^([a-zA-Z]):[\\\/]((?:[^<>:"\\\/\|\?\*]+[\\\/])*)([^<>:"\\\/\|\?\*]+)\.([^<>:"\\\/\|\?\*\s]+)$/gm" or

        # Check if known machines are targeted
        # target_db.each do |key, value|
        #     # If matches a host machine
        #     if nonparams.include? key
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
