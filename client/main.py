#!/usr/bin/python
# -*- coding: utf-8 -*-
import sys,select,signal,argparse,os.path,json
path = os.path.dirname(__file__)
path = os.path.join(path, "..")
sys.path.insert(0, path)
from rpcservice import AsyncRpcService as RpcService
from pysproto.sproto import SprotoRpc
import time
import struct
import threading
import thread
import pygame
from pygame.locals import *
import sys
from game import *

class Client:
	def __init__(self, args):
		self.m_Addr = (args["host"], args["port"])
		self.m_Pid = args["pid"]
		self.init_protocol()

	def start(self):
		self.m_RpcObj = RpcService(self.m_Addr, self.m_SprotoObj, self)
		self.m_RpcObj.start()
		thread = threading.Thread(target=self.network_loop)
		thread.daemon = True
		thread.start()
		self.m_RpcObj.send("c2gs_login", {'pid':self.m_Pid})
		self.m_GameObj = CGameObj(self.m_Pid,self.m_RpcObj)
		self.m_GameObj.main_loop()

	def init_protocol(self):
		spb_file = "../build/sproto.spb"
		f = open(spb_file, "rb")
		pbin = f.read()
		f.close()
		self.m_SprotoObj = SprotoRpc(pbin, 'BasePackage')

	def network_loop(self):
		while True:
			try:
				# wait for input from stdin & socket
				inputready, outputready, exceptready = select.select([self.m_RpcObj.fd()], [], [], 1)
				if inputready:
					if not self.m_RpcObj.recv():
						sys.stdout.write("disconnect!"+os.linesep)
						sys.stdout.flush()
						break
			except Exception, e:
				break
		thread.interrupt_main()

def init():
	pid = 1
	if len(sys.argv) > 1:
		pid = int(sys.argv[1])
	f = file('config.json')
	cfg = json.load(f)
	f.close()
	cs = Client({'host':cfg["host"],'port':cfg["port"],'pid':pid})
	cs.start()

if __name__ == "__main__":
	init()