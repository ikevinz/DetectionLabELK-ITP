# post processing for matching keylogs with bashlogs

import re
import os
import argparse

logsFolder = ""


def getArgs():
	global logsFolder
	parser = argparse.ArgumentParser()
	parser.add_argument("--logsFolder", help="path where logs are stored (default=/tmp/USAGE_LOGS)", action="store")
	args = parser.parse_args()
	if isinstance(args.logsFolder, str):
		logsFolder = args.logsFolder
		if not logsFolder[-1:] == "/":
			logsFolder += "/"
	else:
		logsFolder = "/tmp/USAGE_LOGS/"

def processLogs(shellFile):
	with open(f"{logsFolder}keylogger.log", 'r') as f:
		key_logs = f.readlines()

	with open(shellFile, 'r') as f:
		shell_logs = f.readlines()
		shell_logs.reverse()

	if not (key_logs == [] or shell_logs == []):
		# begin processing
		with open(f'{logsFolder}keylog_processed.log', 'a') as processed_fp:
			with open(f'{logsFolder}keylog_ambiguous.log', 'a') as ambiguous_fp:
				for line in key_logs:
					# look for lines with tabs
					if '[TAB]' in line: 
						matches = []
						# cmp with lines in shell_logs, look for match, and if it matches, add it to 
						#print(line)
						regexString = re.sub('\\[TAB\\]', '[\\\\S]*[\\\\s]?', line)
						print(f"REGEX: {regexString}")
						
						for i in shell_logs:
							if re.search(f"^{regexString}$", i):
								matches.append(i)

						# remove duplicates in list
						matches = list(set(matches))
						print(f"Matches = {matches}")

						if len(matches) > 1:
							# not sure which command was used, add to keylog_ambiguous.log
							print("Ambiguous...")
							print(f"{line} has multiple matches: {matches}")
							ambiguous_fp.write(f"Keylog: {line}has multiple matches: {matches}\n\n")

						elif matches == []:
							# no matches from command list, treat as tab? and add to keylog_processed.log
							ambiguous_fp.write(f"No Match: {line}")
						
						else:
							# one match, most likely possibility, add to keylog_processed.log
							print(f"Single Match: {line} and {matches}")
							processed_fp.write(matches[0])
					else:
						processed_fp.write(line)

if __name__ == '__main__':
	getArgs()
	if os.path.exists(f"{logsFolder}"):
		# continue 
		if os.path.exists(f"{logsFolder}keylogger.log") and not os.stat(f"{logsFolder}keylogger.log").st_size == 0:
			# process keylogger.log
			processLogs(f"{logsFolder}keylogger.log")

			if os.path.exists(f"{logsFolder}bash.log"):
				# process bash logs if not size 0
				if not os.stat(f"{logsFolder}bash.log").st_size == 0:
					processLogs(f"{logsFolder}bash.log")
			
			if os.path.exists(f"{logsFolder}zsh.log"):
				# process zsh logs if not size 0
				if not os.stat(f"{logsFolder}zsh.log").st_size == 0:
					processLogs(f"{logsFolder}zsh.log")
	else:
		print("Logs Folder does not exist, exiting...")