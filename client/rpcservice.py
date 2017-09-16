# -*- coding: utf-8 -*-
import logging, time, struct
import socket
import sys

class AsyncRpcService:
    SESSION_ID = 1
    def __init__(self, addr, proto, owner=None):
        self.addr = addr
        self.sock = None
        self.proto = proto
        self.close = False
        self.owner = owner
        self.buf = ""

    def start(self):
        if self.sock:
            return True
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        try:
            sock.connect(self.addr)
            sock.setblocking(0)
            print "start sock ok",self.addr,sock
        except socket.error, e:
            print "start error"
            logging.info("conncect to server %s failed, %s", self.addr, str(e))
            return False

        self.sock = sock
        return True

    def stop(self):
        self.sock.close()

    def is_close(self):
        return self.close

    def _read(self):
        if self.close:
            return False
        try:
            buf = self.sock.recv(4*1024)
            if not buf:
                self.close = True
                return False
            self.buf = self.buf + buf
        except socket.error, e:
            # print "sock error: %s"%e
            pass

        if len(self.buf) < 2:
            return None
 
        plen, = struct.unpack('!H', self.buf[:2])
        if len(self.buf) < plen + 2:
            return None

        data = self.buf[2:plen+2]
        self.buf = self.buf[plen+2:]
        return data

    def _write(self, data):
        try:
            self.sock.sendall(data)
        except socket.error, e:
            logging.info("write socket failed:%s", str(e))


    def _dispatch(self, data):
        p = self.proto.dispatch(data)
        protoname = p['proto']
        msg = p['msg']
        self._dispatch_request(protoname, msg)

    def _dispatch_request(self, protoname, msg):
        if self.owner:
            #if not (protoname in ["gs2c_frame_data","gs2c_ping"]):
            #print "recv net data",protoname,msg
            if protoname == "gs2c_loginsuc":
                self.owner.m_GameObj.init_fsm(msg)
            elif protoname == "gs2c_frame_data":
                self.owner.m_GameObj.recv_frame(msg["frame_data"])
            elif protoname == "gs2c_ping":
                self.owner.m_GameObj.server_ping(msg["session"], msg["is_resp"])
            elif protoname == "gs2c_rtt_data":
                self.owner.m_GameObj.gs2c_rtt_data(msg)
            elif protoname == "gs2c_frame_cache_data":
                self.owner.m_GameObj.gs2c_frame_cache_data(msg["frame_cache"])
        else:
            print "%s no handler" % protoname, msg
        

    def _send(self, data):
        self._write(struct.pack("!H", len(data)) + data)

    def send(self, protoname, msg):
        ud = {"timestamp" : int(time.time())}
        pack = self.proto.request(protoname, msg, None, ud)
        self._send(pack)

    def fd(self):
        if not self.sock:
            return None
        else:
            return self.sock.fileno()
        
    def recv(self):
        while True:
            data = self._read()
            if data:
                self._dispatch(data)
            elif self.close:
                return False
            else:
                break
        return True
