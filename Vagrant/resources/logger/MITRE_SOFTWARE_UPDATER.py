import requests, json
from stix2 import MemoryStore, Filter
from itertools import chain

def get_data_from_branch(domain, branch="master"):
    """get the ATT&CK STIX data from MITRE/CTI. Domain should be 'enterprise-attack', 'mobile-attack' or 'ics-attack'. Branch should typically be master."""
    stix_json = requests.get(f"https://raw.githubusercontent.com/mitre/cti/{branch}/{domain}/{domain}.json").json()
    return MemoryStore(stix_data=stix_json["objects"])

def get_software(thesrc):
    return list(chain.from_iterable(
        thesrc.query(f) for f in [
            Filter("type", "=", "tool"), 
            Filter("type", "=", "malware")
        ]
    ))

def main():
    src = get_data_from_branch("enterprise-attack")

    software = get_software(src)

    end_dict = {}

    # Maps software/malware in MITRE SOFTWARE to their techniques and tactics employed
    for i in software:
        print("Extracting Relations for: " + i.name)
        #get name and id of software
        id = i.id
        name = i.name
        
        techniques = []
        tactics = []
        techniques_id = []

        # in relationships, pull out all the attack patterns associated with software/malware id.
        software_to_techniques = src.query([Filter('type', '=', 'relationship'), Filter('source_ref', '=', i.id), Filter('relationship_type', '=', 'uses'), ])

        # Maps software relations to tactics and techniques
        for r in software_to_techniques:
            # Finding Technique
            ttp_mapping = src.get(r.target_ref)

            # Adding Tactic to list
            if hasattr(ttp_mapping, 'kill_chain_phases'):
                tactics.append(ttp_mapping.kill_chain_phases[0].phase_name)

            # If subtechnique, append the parent technique to the name
            if hasattr(ttp_mapping, 'x_mitre_is_subtechnique') and ttp_mapping.x_mitre_is_subtechnique is True:
                sub = src.query([Filter('type', '=', 'relationship'), Filter('source_ref', '=', r.target_ref), Filter('relationship_type', '=', 'subtechnique-of')])
                sub_mapping = src.get(sub[0].target_ref)
                techniques.append(sub_mapping.name + ": " + ttp_mapping.name)
            else:
                # Not subtechnique
                techniques.append(ttp_mapping.name)
            
            # add technique id
            techniques_id.append(ttp_mapping.external_references[0].external_id)

        #save to dict
        tmp = {"tactics": list(dict.fromkeys(tactics)), "techniques": techniques, "techniques_id": techniques_id}
        end_dict[i.name] = tmp

    print("Relation Mapping Complete!")
    print("Extracting to MITRE_SOFTWARE.json...")
    json_object = json.dumps(end_dict, indent = 4)  

    # Writing to DB JSON FILE
    with open("MITRE_SOFTWARE.json", "w") as outfile:
        outfile.write(json_object)
    print("Extraction Complete!")

if __name__ == "__main__":
    main()

