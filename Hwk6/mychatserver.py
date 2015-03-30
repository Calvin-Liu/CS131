import sys
import os
import json
import time
import datetime
import urllib2
import logging
from twisted.internet.protocol import Factory,Protocol
from twisted.protocols.basic import LineReceiver
from twisted.internet import reactor, protocol
from twisted.internet.endpoints import TCP4ClientEndpoint
from twisted.internet.defer import Deferred
from twisted.web.client import getPage

ports = {
	'Alford': 12150,
	'Bolden': 12151,
	'Hamilton': 12152,
	'Parker': 12153,
	'Powell': 12154
}

allowedToConnect = {
	"Alford" : ["Parker", "Powell"],
	"Bolden" : ["Parker", "Powell"],
	"Powell" : ["Alford", "Bolden"],
	"Hamilton" : ["Parker"],
	"Parker" : ["Alford", "Bolden", "Hamilton"]
}

class ChatProtocol(LineReceiver):
	def __init__(self, factory):
		self.factory = factory

	def makeLog(self, msg):
		line = "{0}: {1}".format(self.factory.name, msg)
		logging.debug(line)
		print line

	def connectionMade(self):
		self.factory.numOfClients += 1
		message = "New connection! Number of clients: {0}".format(self.factory.numOfClients)
		self.makeLog(message)

	def connectionLost(self, because):
		self.factory.numOfClients -= 1
		message = "Connection closed! Number of clients: {0}".format(self.factory.numOfClients)
		self.makeLog(message)

	def lineReceived(self, line):
		message = "Received" + line
		self.makeLog(message)

		args = line.strip().split()
		if args[0] == "WHATSAT":
			args = line.strip().split()
			if len(args) != 4:
				self.transport.write("? " + ''.join(line) + '\n')
				self.makeLog("Bad WHATSAT request.")
				return

			clientID = args[1]
			clientFromRadius = int(args[2])
			clientItemsToReceive = int(args[3])
			if clientFromRadius > 50:
				clientFromRadius = 50
			if clientItemsToReceive > 20:
				clientItemsToReceive = 20

			if clientID not in self.factory.users:
				self.makeLog("Client location unknown.")
				self.transport.write("Client location unknown.\n")
				return

			_, _, _, _, clientCoordinates, _ = self.factory.users[clientID]['msg'].split(" ")

			clientCoordinates = re.sub(r'[-]', ' -', clientCoordinates)
			clientCoordinates = re.sub(r'[+]', ' +', clientCoordinates)
			coordinateString = ",".join(clientCoordinates.split())

			requestURL = "{0}location={1}&radius={2}&sensor=false&key={3}".format("https://maps.googleapis.com/maps/api/place/nearbysearch/json?", coordinateString, clientFromRadius, "AIzaSyBIUbrDobhNCPhkjNTFEQ2mJFMPER50C3M")
			self.makeLog("Conducting API reuqest to Google Maps at: {0}".format(requestURL))
			placesResponse = getPage(requestURL)
			placesResponse.addCallback(
				lambda res:
				self.processPlaces(res, int(clientItemsToReceive), clientID))
			return

			
		if args[0] == "IAMAT":
			if len(args) != 4:
				self.transport.write("? " + ''.join(line) + '\n')
				self.makeLog("Invalid IAMAT request")
				return

			clientID = args[1]
			clientCoordinates = args[2]
			clientTime = float(args[3])

			differenceInTime = time.time() - clientTime;
			timeString = ""
			if(differenceInTime > 0):
				timeString = "+" + repr(differenceInTime)
			else:
				timeString = "-" + repr(differenceInTime)
			response = "AT {0} {1} {2} {3} {4}".format(self.factory.name, differenceInTime, clientID, clientCoordinates, clientTime)
			self.transport.write(response+"\n")

			#latest IAMAT msg from every client
			if clientID not in self.factory.users:
				self.makeLog("New Client [IAMAT]: {0}".format(clientID))
				self.factory.users[clientID] = {"msg":response, "time":clientTime}

				#flood server location
				self.updateLocation(response)
			else:
				if(self.factory.users[clientID]['time'] > clientTime):
					self.makeLog("Existing Client Expired [IAMAT]: {0}".format(clientID))
					return
				else:
					self.makeLog("Existing Client Updated [IAMAT]: {0}".format(clientID))
					self.factory.users[clientID]["msg"] = response
					self.factory.users[clientID]["time"] = clientTime
					self.updateLocation(response)

			return

		if args[0] == "AT":
			if len(args) != 6:
				self.makeLog('Wrong AT Request.')
				return
			
			serverName = args[1]
			timeString = args[2]
			clientID = args[3]
			clientCoordinates = args[4]
			clientTime = args[5]

			response = " ".join(args)
			self.makeLog("Flood Received:" + response)

			#update the response server ID
			args[4] = self.factory.name
			response = " ".join(args)

			#Have to track latest IAMAT msg from every client
			if clientID not in self.factory.users:
				self.makeLog("New Client [IAMAT]: {0}".format(clientID))
				self.factory.users[clientID] = {"msg":response, "time":clientTime}
				self.updateLocation(response)
			else:
				#if we see an older client IAMAT msg disregard
				if(self.factory.users[clientID]['time'] >= clientTime):
					self.makeLog("Existing Client Expired [IAMAT]: {0}".format(clientID))
					return
				else:
					self.makeLog("Existing Client Updated [IAMAT]: {0}".format(clientID))
					self.factory.users[clientID] = {"msg":response, "time":clientTime}
					self.updateLocation(response)
			return

		else:
			self.makeLog("Bad Request.")

	def updateLocation(self, response):
		if len(allowedToConnect[self.factory.name]) == 0:
			self.makeLog("No neighbors for flooding.")
		else:
			for name in allowedToConnect[self.factory.name]:
				self.makeLog("Flooding to neighbour ({0})".format(name))
				reactor.connectTCP('localhost', ports[name], FloodFactory(response))

	def processPlaces(self, response, limit, clientID):
		json_object = json.loads(response)
		json_object["results"] = json_object["results"][0:int(limit)]
		self.makeLog("API returns: {0}".format(json.dumps(json_object, indent=4)))
		msg = self.factory.users[clientID]["msg"]
		full_response = "{0}\n{1}\n\n".format(msg, json.dumps(json_object, indent=4))
		self.transport.write(full_response)


class FloodProtocol(LineReceiver):
	def __init__(self, factory):
		self.factory = factory
		return

	def connectionMade(self):
		self.sendLine(self.factory.msg)
		self.transport.loseConnection()

class FloodFactory(protocol.ClientFactory):
	def __init__(self, msg):
		self.msg = msg

	def buildProtocol(self, addr):
		return FloodProtocol(self)

class ChatFactory(Factory):
	def __init__(self, name):
		self.name = name
		self.users = {}
		self.portConnections = ports[self.name]
		self.numOfClients = 0
		logging.basicConfig(filename=name+'.log', level=logging.DEBUG)
		logging.debug("Server {0} has stopped. Port {1} is free.".format(self.name, self.portConnections))

	def buildProtocol(self, addr):
		return ChatProtocol(self)

	def stopFactory(self):
		logging.debug("Server {0} has stopped. Port {1} is free.".format(self.name, self.portConnections))
		return self

def main():
	if len(sys.argv) != 2:
		print "Please provide the server name."
		return -1
	name = sys.argv[1]
	if(ports.has_key(name)):
		reactor.listenTCP(ports[name], ChatFactory(name))
		reactor.run()
	else:
		print "No server name found"
		return -1

if __name__ == '__main__':
	main()
