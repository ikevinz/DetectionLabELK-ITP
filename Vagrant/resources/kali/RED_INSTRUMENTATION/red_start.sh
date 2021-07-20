#! /usr/bin/env bash

# This is the script that is used to start the logging for keylogger

main() {
    # Get current user
    myvariable=$USER

    # Start Keylogger
    sudo python3 /opt/RED_INSTRUMENTATION/keylogger/keylogger.py --user $myvariable
    # sudo python3 /vagrant/resources/kali/RED_INSTRUMENTATION/keylogger/keylogger.py --user $myvariable
}

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"

main
exit 0