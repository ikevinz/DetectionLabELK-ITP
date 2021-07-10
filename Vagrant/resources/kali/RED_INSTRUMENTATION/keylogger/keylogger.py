# import needed modules
import os
import getpass
from datetime import datetime
#import pyxhook
import traceback
import threading
import argparse
import time
#import clipboard
import logging
import re
import struct
from shutil import copyfile
import sys, syslog


userIn = []		# string buffer before storing in file (during RETURN)
currIndex = 0 	# cursor index (for insert, backspace, delete, etc)
logsFolder = None
bashPath = ""
zshPath = ""
currUser = ""
#new_hook = None

def setArgs():
	global logsFolder
	global currUser
	parser = argparse.ArgumentParser()
	parser.add_argument("--logsFolder", help="path where logs are stored (default=/opt/RED_INSTRUMENTATION/keylogger/logs)", action="store")
	parser.add_argument("--user", action="store")
	args = parser.parse_args()
	if isinstance(args.logsFolder, str):
		logsFolder = args.logsFolder
		if not logsFolder[-1:] == "/":
			logsFolder += "/"
	else:
		logsFolder = "/opt/RED_INSTRUMENTATION/keylogger/logs/"
	
	if isinstance(args.user, str):
		currUser = args.user

	print(f"Current User is {currUser}")
	print(f"Logs will be stored in {logsFolder}")

def backupAndClear(path):
	try:
		copyfile(path, f"{path}_bak")
		open(path, 'w').close()
		print(f"backed up file @ {path}")
	except:
		print(traceback.format_exc())
		print(f"unable to backup and clear {path}")

"""
# CLIPBOARD LOGGING FUNCTIONS
def logClipboard():
	global logsFolder
	clipboardLogPath = logsFolder+"clipboard.log"
	oldContent = ""
	newContent = ""

	while True:	
		newContent = clipboard.paste()
		if not (newContent == None or newContent == "") and (not newContent == oldContent):
			t = time.strftime("%H:%M:%S", time.localtime())

			with open(clipboardLogPath, 'a') as f:
				if not newContent[-1:] == '\n':
					f.write(f"ENTRY @ {t}\n{newContent}\n")
				else:
					f.write(f"ENTRY @ {t}\n{newContent}")

			oldContent = newContent
			logging.debug(f"Written to clipboard log @ {t}")
			
		time.sleep(1)


def runClipboardLogging():
	print("Starting ClipboardLogger Thread...")
	cbThread = threading.Thread(target=logClipboard, name='clipboardLogger', daemon=True)
	cbThread.start()
"""

# BASH HISTORY LOGGING FUNCTIONS
def findFile(fname, base):
	#logging.debug("Find FIle entered")
	paths = None
	for root,dirs,files in os.walk(base):
		#logging.debug(f"{root} {dirs} {files}")
		# only look in /root or /home
		if fname in files:
			paths = os.path.join(root, fname)
			#logging.debug(f"{paths}")
	return paths

def appendShellLogs(histPath, logsPath):
	#logging.debug("appendShellLogs")
	pos = 0
	# check for file exists
	if not os.path.exists(logsPath):
		open(logsPath, 'a').close()

	# get latest 5 lines from logs
	with open(logsPath, 'r') as f:
		logs = f.readlines()
		#print("logs readline")
		#print(logs)

	if logs and not logs == []:
		latest = logs[-3:]
		#print("latest 3")
		#print(latest)

		with open(histPath, 'r') as g:
			hist = g.readlines()
			#print("history readline")
			#print(hist)

		if hist and not hist == []:
			#for i in range(0, len(hist)):
				#print("I: {0} | CONT: {1}".format(i, hist[i]))

			hasMatch = False
			for pos in range(0, len(hist)):
				#print("pos = " + str(pos))
				#print("{0} @ POS {1}".format(hist[pos], pos))
				if hist[pos] == latest[0]:
					# possible match, checking next 2 entries
					#print("match found @ " + str(pos))
					try:
						if hist[pos+1] == latest[1] and hist[pos+2] == latest[2]:
							# copy lines pos -> len(hist) into logs
							hist = hist[pos+3:]
							if not hist == []:
								with open(logsPath, 'a') as f:
									f.writelines(hist)
							hasMatch = True
							break
					except IndexError:
						#print("END OF FILE, NO MATCHES")
						break

			if not hasMatch:
				with open(logsPath, 'a') as f:
					f.writelines(hist)
	
	else:
		with open(histPath, 'r') as g:
			with open(logsPath, 'a') as f:
				f.writelines(g.readlines())

	#print("history saved")

def logShellHistory(runOnce=False):
	global logsFolder, bashPath, zshPath
	
	#logging.basicConfig(level=logging.DEBUG, format='%(threadName)s %(message)s')
	#logging.debug("Run logShellHistory")

	bashLogsPath = logsFolder+"bash.log"
	zshLogsPath = logsFolder+"zsh.log"

	#logging.debug("OUT: {0} {1} {2} {3} {4}".format(user, bashPath, zshPath, bashLogsPath, zshLogsPath))
	if not runOnce:
		while True:
			#logging.debug("While True entered....")
			if bashPath and not bashPath == "":
				appendShellLogs(bashPath, bashLogsPath)
				t = time.strftime("%H:%M:%S", time.localtime())
				logging.debug(f"Ran appendShellLogs @ {t}")
			else:
				print("bash history not available, skipping")
			
			if zshPath and not zshPath == "":
				appendShellLogs(zshPath, zshLogsPath)
				t = time.strftime("%H:%M:%S", time.localtime())
				logging.debug(f"Ran appendShellLogs @ {t}")
			else:
				print("zsh history not available, skipping")
			time.sleep(5*60)								# do every 5mins
	else:
		t = time.strftime("%H:%M:%S", time.localtime())
		logging.debug(f"Ran appendShellLogs @ {t}")
		if bashPath and not bashPath == "":
			appendShellLogs(bashPath, bashLogsPath)
			
		if zshPath and not zshPath == "":
			appendShellLogs(zshPath, zshLogsPath)
	#logging.debug("leave logShellHistory")


def runShellLogging():
	#print("Starting Shell Logger Thread...")
	# start bashlogger
	blThread = threading.Thread(target=logShellHistory, name='shellLogger', daemon=True)
	blThread.start()
	#print("Started LOGGER")


qwerty_map = {
	2: "1", 3: "2", 4: "3", 5: "4", 6: "5", 7: "6", 8: "7", 9: "8", 10: "9", 11: "0", 12: "-", 13: "=", 14: "[BACKSPACE]", 
	15: "[TAB]", 16: "q", 17: "w", 18: "e", 19: "r", 20: "t", 21: "y", 22: "u", 23: "i", 24: "o", 25: "p", 26: "[", 27: "]", 
	28: "[ENTER]", 29: "[CTRL]", 97: "[CTRL]", 100: "[ALT]",
	30: "a", 31: "s", 32: "d", 33: "f", 34: "g", 35: "h", 36: "j", 37: "k", 38: "l", 39: ";", 40: "'", 41: "`", 42: "[SHIFT]", 43: "\\", 
	44: "z", 45: "x", 46: "c", 47: "v", 48: "b", 49: "n", 50: "m", 51: ",", 52: ".", 53: "/", 54: "[SHIFT]", 55: "[FN]", 56: "[ALT]", 57: " ", 58: "[CAPS_LOCK]",
	105: "LEFT", 106: "RIGHT", 103: "UP", 108: "DOWN", 111: "DEL", 107: "END", 102: "HOME", 69: "NUM_LOCK", 104: "PAGE_UP", 109: "PAGE_DOWN",
	82: "0", 83: ".", 79: "1", 80: "2", 81: "3", 75: "4", 76: "5", 77: "6", 71: "7", 72: "8", 73: "9", 98: "/", 55: "*", 74: "-", 78: "+", 96: "[ENTER]"
}

shifted_qwerty_map = {
	2: "!", 3: "@", 4: "#", 5: "$", 6: "%", 7: "^", 8: "&", 9: "*", 10: "(", 11: ")", 12: "_", 13: "+", 14: "[BACKSPACE]", 
	15: "[TAB]", 16: "Q", 17: "W", 18: "E", 19: "R", 20: "T", 21: "Y", 22: "U", 23: "I", 24: "O", 25: "P", 26: "{", 27: "}", 
	28: "[ENTER]", 29: "[CTRL]", 97: "[CTRL]", 100: "[ALT]",
	30: "A", 31: "S", 32: "D", 33: "F", 34: "G", 35: "H", 36: "J", 37: "K", 38: "L", 39: ":", 40: "\"", 41: "~", 42: "[SHIFT]", 43: "|", 
	44: "Z", 45: "X", 46: "C", 47: "V", 48: "B", 49: "N", 50: "M", 51: "<", 52: ">", 53: "?", 54: "[SHIFT]", 55: "[FN]", 56: "[ALT]", 57: " ", 58: "[CAPS_LOCK]",
	105: "LEFT", 106: "RIGHT", 103: "[UP]", 108: "[DOWN]", 111: "DEL", 107: "END", 102: "HOME", 69: "NUM_LOCK", 104: "PAGE_UP", 109: "PAGE_DOWN",
	82: "0", 83: ".", 79: "1", 80: "2", 81: "3", 75: "4", 76: "5", 77: "6", 71: "7", 72: "8", 73: "9", 98: "/", 55: "*", 74: "-", 78: "+", 96: "[ENTER]"
}

# KEYBOARD INPUT LOGGING FUNCTIONS
def runKeyLogging():
	global logsFolder

	# specify the name of the file (can be changed )
	log_file = logsFolder+'keylogger.log'

	# the logging function with {event parm}
	def OnKeyPress(ch):
		global userIn, currIndex, currUser
		
		if ch == "[ENTER]":
				#print('ENTERED')
				if not userIn == []:
					with open(log_file, "a") as f:  # open a file as f with Append (a) mode
						f.write(f"{''.join(userIn)}\n")
						# Log to syslog as well
						syslog.openlog(ident=currUser, facility=syslog.LOG_LOCAL7)
						syslog.syslog(syslog.LOG_DEBUG, f"{''.join(userIn)}")
				userIn = [] # clear userIn
				currIndex = 0
		else:
			if 'LEFT' in ch: # if Left pressed and not at start of string
				if not currIndex <= 0:
					currIndex -= 1
				#print("str len = {0} | index = {1}".format(len(userIn), currIndex))
			elif 'RIGHT' in ch: # if Right pressed and not at end of string
				if not currIndex >= len(userIn):
					currIndex += 1
				#print("str len = {0} | index = {1}".format(len(userIn), currIndex))

			elif 'BACKSPACE' in ch:
				if currIndex == 0:
					pass # backspace does nth at pos 0
				else:
					userIn = userIn[:currIndex-1] + userIn[currIndex:]
					currIndex -=1
				#print("USERIN: " + "".join(userIn))
			elif 'DEL' in ch:
				userIn = userIn[:currIndex] + userIn[currIndex+1:] # remove single character

				#print("USERIN: " + "".join(userIn))
			elif 'END' in ch:
				currIndex = len(userIn) # move to end of string
			elif 'HOME' in ch:
				currIndex = 0

			elif any(x in ch for x in ['CTRL', 'ALT', 'NUM_LOCK', 'PAGE_', 'SHIFT', 'UP', 'DOWN']): #, 'CAPS_LOCK', 'SHIFT']):
				pass # prevent weird characters from being entered

			else:
				userIn.insert(currIndex, ch)
				print("USERIN: " + "".join(userIn))
				currIndex += 1
				#print("str len = {0} | index = {1}".format(len(userIn), currIndex))

	with open("/proc/bus/input/devices") as f:
		lines = f.readlines()

		pattern = re.compile("Handlers|EV=")
		handlers = list(filter(pattern.search, lines))

		pattern = re.compile("EV=120013")
		for idx, elt in enumerate(handlers):
			if pattern.search(elt):
				line = handlers[idx - 1]
		pattern = re.compile("event[0-9]")
		infile_path = "/dev/input/" + pattern.search(line).group(0)

	FORMAT = 'llHHI'
	EVENT_SIZE = struct.calcsize(FORMAT)

	in_file = open(infile_path, "rb")

	event = in_file.read(EVENT_SIZE)
	typed = ""
	
	shifted = False

	while event:
		(_, _, type, code, value) = struct.unpack(FORMAT, event)

		if code == 54 or code == 42:
			if value == 0:
				shifted = False
			else: 
				shifted = True

		if code != 0 and type == 1 and value == 1:
			print(f"[{code}]")

			if code in qwerty_map:
				if shifted:
					OnKeyPress(shifted_qwerty_map[code])
				else:
					OnKeyPress(qwerty_map[code])

		try:
			event = in_file.read(EVENT_SIZE)
		except KeyboardInterrupt:
			print("\nBefore stopping keylogger, ensure all shell tabs/windows \n\
have been closed (excluding this tab), before stopping keylogger.py \n\
This ensures that shell history is updated!\n")

			opt = input("Stop keylogger? [y/n]: ")

			# if not y, ignore exit request
			if not (opt == None or opt == '') and opt == 'y':
				logShellHistory(runOnce=True)
				in_file.close()
				break
		except:
			print(traceback.format_exc())
			break


if __name__ == "__main__":
	# print("To work properly, ensure this program is started by the primary user and console window.")
	# input("Press enter to continue")

	# print("Backup of .bash_history and .zsh_history will be made, and history files will be cleared.\nBacked up logs are stored in user home directory.")
	# input("Press enter to acknowledge")

	# run backing up of history file, and clear history file
	# while True:
	# 	isRootUser = input("Is the current user root? [Y / N]")
	# 	if isRootUser.lower() == 'y':
	# 		base = '/root'
	# 		break
	# 	elif isRootUser.lower() == 'n':
	# 		currUser = input("Enter current username:")
	# 		if not currUser == '' and os.path.exists(f'/home/{currUser}'):
	# 			base = f'/home/{currUser}'
	# 			break
	# 		else:
	# 			print('Invalid username!\n')
	# 	else:
	# 		print("Not a valid input!\n")
	# currUser = pwd.getpwuid(os.getuid()).pw_name
	setArgs()
	base = f'/home/{currUser}'
	#logging.debug(f"{user}")
	bashPath = findFile(".bash_history", base)	# for the older kali using bash
	#logging.debug("2")
	zshPath = findFile(".zsh_history", base)	# for the newer kali using zsh
							
	startShellLogging = True
							
	if bashPath and os.path.exists(bashPath):
		backupAndClear(bashPath)
		print("Backed up .bash_history")
	if zshPath and os.path.exists(zshPath):
		backupAndClear(zshPath)
		print("Backed up .zsh_history")
	if not zshPath and not bashPath:
		print("Unable to detect any shell logs available, shell logging will be ignored.")
		startShellLogging = False					
	print("Starting...")

	

	if not os.path.exists(logsFolder):
		# create the logs folder
		os.makedirs(logsFolder)

	logging.basicConfig(level=logging.DEBUG, format='%(threadName)s %(message)s')
	#logging.debug("some text")
	#runClipboardLogging()
	if startShellLogging:
		runShellLogging()
	runKeyLogging()
