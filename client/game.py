# -*- coding: utf-8 -*-
import socket
import time
import os
import math
import pygame
from pygame.locals import *
import sys
reload(sys)
sys.setdefaultencoding('utf-8')
import random
import Queue

#===========const defines============
COLOR_BLACK = (0,0,0)
COLOR_WHITE = (255,255,255)
COLOR_CHOCOLATE = (139,69,19)

COLOR_RED = (255,0,0)
COLOR_YELLOW = (255,255,0)
COLOR_GREEN = (0,255,0)
COLOR_BLUE = (0,255,255)
COLOR_GRAY = (138,138,138)
COLOR_DARKBLUE = (0,0,255)
COLOR_PINK = (241,158,194)
COLOR_GOLDEN = (255,215,0)

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600

FRAME_TICK = 10

GAME_RND_SEED = None
FSM_OPEN = False
ENTITY_ID = 0

ENTITY_ENEMY = 1
ENTITY_BULLET = 2
ENTITY_PLAYER = 3

DIR_UP = 1
DIR_DOWN = 2
DIR_LEFT = 3
DIR_RIGHT = 4

STATUS_KEY_DOWN = 1
STATUS_KEY_UP = 2

ACTION_ENTER = 1
ACTION_LEAVE = 2
ACTION_ATTACK = 3
ACTION_MOVE = 4

DIR_MAP = {
    K_w:DIR_UP,
    K_UP:DIR_UP,
    K_a:DIR_LEFT,
    K_LEFT:DIR_LEFT,
    K_s:DIR_DOWN,
    K_DOWN:DIR_DOWN,
    K_d:DIR_RIGHT,
    K_RIGHT:DIR_RIGHT,
}

def SetRndSeed(seed):
    global GAME_RND_SEED
    GAME_RND_SEED = seed
    random.seed(GAME_RND_SEED)

def RandomInt(_min, _max):
    global GAME_RND_SEED
    assert(GAME_RND_SEED)
    return random.randint(_min, _max)

def RandomList(lst):
    size = len(lst)
    if size == 0:
        return None
    pos = RandomInt(1, size) - 1
    return lst[pos]

def Is2RectsCross(cpos1, w1, h1, cpos2, w2, h2):
    cx1,cz1 = cpos1
    cx2,cz2 = cpos2
    lx1 = cx1 - w1/2
    rx1 = cx1 + w1/2
    tz1 = cz1 - h1/2
    bz1 = cz1 + h1/2

    lx2 = cx2 - w2/2
    rx2 = cx2 + w2/2
    tz2 = cz2 - h2/2
    bz2 = cz2 + h2/2

    if (lx1 > rx2) or (rx1 < lx2) or (tz1 > bz2) or (bz1 < tz2):
        return False
    return True


class CBaseObj(object):
    def __init__(self, gobj):
        self.m_GameObj = gobj
        global ENTITY_ID
        ENTITY_ID = ENTITY_ID + 1
        self.m_ID = ENTITY_ID

    def draw(self):
        self.m_GameObj.game_draw_rect(self.m_Color, self.lt_pos(), self.rb_pos())

    def on_hit(self):
        self.m_Blood = self.m_Blood - 1

    def is_dead(self):
        return self.m_Blood <= 0

    def is_bullet(self):
        return self.m_Type == ENTITY_BULLET

    def is_player(self):
        return self.m_Type == ENTITY_PLAYER

    def is_enemy(self):
        return self.m_Type == ENTITY_ENEMY

    def pos(self):
        return self.m_Pos

    def lt_pos(self):
        return [self.m_Pos[0] - self.m_Width/2, self.m_Pos[1] - self.m_Height/2]

    def rb_pos(self):
        return [self.m_Pos[0] + self.m_Width/2, self.m_Pos[1] + self.m_Height/2]

    def release(self):
        self.m_GameObj = None

    def is_out_screen(self):
        return (self.m_Pos[0] < 0) or (self.m_Pos[0] > SCREEN_WIDTH) or (self.m_Pos[1] < 0) or (self.m_Pos[1] > SCREEN_HEIGHT)

    def on_update(self):
        pass

    def update(self):
        if self.is_dead() or self.is_out_screen():
            if self.is_dead() and self.is_enemy():
                self.m_GameObj.add_score(self.m_RewardScore)
            self.m_GameObj.destroy_entity(self)
            return
        if self.m_Dir:
            if self.m_Dir == DIR_UP:
                self.m_Pos[1] = self.m_Pos[1] - self.m_Speed/4
            elif self.m_Dir == DIR_DOWN:
                self.m_Pos[1] = self.m_Pos[1] + self.m_Speed/4
            elif self.m_Dir == DIR_LEFT:
                self.m_Pos[0] = self.m_Pos[0] - self.m_Speed/4
            elif self.m_Dir == DIR_RIGHT:
                self.m_Pos[0] = self.m_Pos[0] + self.m_Speed/4

            if self.is_player():
                if self.m_Pos[0] < 0:
                    self.m_Pos[0] = 0
                elif self.m_Pos[0] > SCREEN_WIDTH:
                    self.m_Pos[0] = SCREEN_WIDTH
                elif self.m_Pos[1] < 0:
                    self.m_Pos[1] = 0
                elif self.m_Pos[1] > SCREEN_HEIGHT:
                    self.m_Pos[1] = SCREEN_HEIGHT
        self.on_update()


class CEnemyObj(CBaseObj):
    m_Type = ENTITY_ENEMY
    def __init__(self, gobj):
        self.m_Width = RandomInt(30, 50)
        self.m_Height = RandomInt(30, 50)
        self.m_Color = RandomList([COLOR_BLACK,COLOR_RED,COLOR_GREEN,COLOR_BLUE,COLOR_GOLDEN])
        self.m_Pos = [RandomInt(1, SCREEN_WIDTH-1),RandomInt(1, 50)]
        self.m_Speed = RandomInt(20,60)
        self.m_Blood = 1
        self.m_RewardScore = 10
        super(CEnemyObj,self).__init__(gobj)
        self.m_Dir = DIR_DOWN

    def draw(self):
        super(CEnemyObj,self).draw()
        text = self.m_GameObj.m_ChineseFont.render(u"方块%d"%(self.m_ID), True, self.m_Color)
        self.m_GameObj.m_Surface.blit(text, (self.m_Pos[0],self.m_Pos[1]))


class CBulletObj(CBaseObj):
    m_Type = ENTITY_BULLET
    def __init__(self, gobj, args):
        self.m_Width = 15
        self.m_Height = 15
        self.m_Speed = 15
        self.m_Color = COLOR_YELLOW
        self.m_Pos = [args["pos"]["x"],args["pos"]["z"]]
        super(CBulletObj,self).__init__(gobj)
        self.m_Blood = 1
        self.m_Dir = DIR_UP

class CPlayerObj(CBaseObj):
    m_Type = ENTITY_PLAYER
    def __init__(self, gobj, args):
        self.m_Pid = args["pid"]
        self.m_Name = args["name"]
        self.m_Color = (args["color"]["r"],args["color"]["g"],args["color"]["b"])
        self.m_Pos = [args["pos"]["x"],args["pos"]["z"]]
        self.m_Width = 40
        self.m_Height = 40
        self.m_Speed = 30
        self.m_Dir = None
        self.m_InAttack = False
        self.m_AckLoopCnt = 0
        self.m_Blood = 3000
        super(CPlayerObj,self).__init__(gobj)

    def name(self):
        return u"%s[%d,%d]"%(self.m_Name,self.m_Pos[0],self.m_Pos[1])

    def draw(self):
        super(CPlayerObj,self).draw()
        text = self.m_GameObj.m_ChineseFont.render(self.name(), True, self.m_Color)
        self.m_GameObj.m_Surface.blit(text, (self.m_Pos[0],self.m_Pos[1]))

    def on_update(self):
        if self.m_InAttack:
            if (self.m_AckLoopCnt%5) == 0:
                self.m_GameObj.create_entity(ENTITY_BULLET, {"pos":{"x":self.m_Pos[0],"z":self.m_Pos[1]}})
            self.m_AckLoopCnt = self.m_AckLoopCnt + 1

    def handle_move(self, iDir, status):
        if status == STATUS_KEY_UP:
            if self.m_Dir == iDir:
                self.m_Dir = None
        elif status == STATUS_KEY_DOWN:
            if self.m_Dir == None:
                self.m_Dir = iDir

    def handle_attack(self, status):
        if status == STATUS_KEY_UP:
            self.m_InAttack = False
        elif status == STATUS_KEY_DOWN:
            self.m_InAttack = True
            self.m_AckLoopCnt = 0

    def touch_key_up(self, key):
        if not self.m_GameObj:
            return
        if key in [K_w,K_a,K_s,K_d,K_LEFT,K_RIGHT,K_UP,K_DOWN]:
            iDir = DIR_MAP[key]            
            ctrl = {
                'pid':self.m_Pid,
                'action':ACTION_MOVE,
                'move_info': {
                    'dir':iDir,
                    'status':STATUS_KEY_UP,
                }
            }
            self.m_GameObj.m_RpcObj.send("c2gs_ctrl_data", {'ctrl_data':ctrl})
        elif key in [K_RCTRL,K_SPACE]:
            ctrl = {
                'pid':self.m_Pid,
                'action':ACTION_ATTACK,
                'attack_info': {
                    'status':STATUS_KEY_UP,
                }
            }
            self.m_GameObj.m_RpcObj.send("c2gs_ctrl_data", {'ctrl_data':ctrl})

    def touch_key_down(self, key):
        if not self.m_GameObj:
            return
        if key in [K_w,K_a,K_s,K_d,K_LEFT,K_RIGHT,K_UP,K_DOWN]:
            iDir = DIR_MAP[key]            
            ctrl = {
                'pid':self.m_Pid,
                'action':ACTION_MOVE,
                'move_info': {
                    'dir':iDir,
                    'status':STATUS_KEY_DOWN,
                }
            }
            self.m_GameObj.m_RpcObj.send("c2gs_ctrl_data", {'ctrl_data':ctrl})
        elif key in [K_RCTRL,K_SPACE]:
            ctrl = {
                'pid':self.m_Pid,
                'action':ACTION_ATTACK,
                'attack_info': {
                    'status':STATUS_KEY_DOWN,
                }
            }
            self.m_GameObj.m_RpcObj.send("c2gs_ctrl_data", {'ctrl_data':ctrl})



class CGameObj:
    def __init__(self, pid, rpcobj):
        self.m_RpcObj = rpcobj
        self.m_MainRPid = pid
        self.m_AllEntityObjects = {}
        self.m_PlayerObjects = {}
        self.m_EnemyObjects = {}
        self.m_BulletObjects = {}
        self.m_MainRole = None
        self.m_lRTTValues = []
        self.m_dRTTSessions = {}
        self.m_RTT = 0
        self.m_OldRTT = 0
        self.m_MaxRTT = -1
        self.m_MinRTT = 10000
        self.m_AvgRTT = 0
        self.m_SumRTT = 0
        self.m_RTTStartMS = time.time()
        self.m_RTTLastMS = time.time()
        self.m_CurScore = 0
        self.m_GoalScore = 3000
        self.m_GameOver = False
        self.m_GSRTT = None
        self.m_PassTime = 0 #cs
        self.m_FrameQueue = Queue.Queue()
        self.m_GSFrameNo = 0
        self.m_FsmInitData = None

    def release(self):
        self.m_RpcObj = None
        self.m_MainRole = None

    def listen_event(self):
        for event in pygame.event.get():
            if event.type == QUIT:
                sys.exit()

            elif event.type == KEYDOWN:
                if self.m_MainRole:
                    self.m_MainRole.touch_key_down(event.key)

            elif event.type == KEYUP:
                if self.m_MainRole:
                    self.m_MainRole.touch_key_up(event.key)

    def update_logic(self):
        self.m_PassTime += 100.0/FRAME_TICK
        if self.m_GameOver:
            return
        if self.m_FrameQueue.empty():
            #print self.m_PassTime,"no frame"
            return
        while self.m_FrameQueue.qsize() > 0:
            data = self.m_FrameQueue.queue[0]
            if data["timestamp"] - self.m_GSFsmInitTime <= self.m_PassTime:
                data = self.m_FrameQueue.get_nowait()
                self.update_frame(data)
            else:
                break

        if self.m_GameOver:
            for id,obj in self.m_BulletObjects.items():
                self.destroy_entity(obj)
            for id,obj in self.m_EnemyObjects.items():
                self.destroy_entity(obj)

    def game_draw_rect(self, color, lt_pos, rb_pos, _width = 0):
        width = rb_pos[0] - lt_pos[0]
        height = rb_pos[1] - lt_pos[1]
        pygame.draw.rect(self.m_Surface, color, ((lt_pos[0],lt_pos[1]),(width,height)), _width)

    def new_player(self, args):
        return self.create_entity(ENTITY_PLAYER, args)

    def get_player(self, pid):
        for oid,obj in self.m_PlayerObjects.items():
            if obj.m_Pid == pid:
                return obj
        return None

    def del_player(self, pid):
        pobj = self.get_player(pid)
        if pobj:
            self.destroy_entity(pobj)

    def create_entity(self, etype, args=None):
        obj = None
        if etype == ENTITY_PLAYER:
            obj = CPlayerObj(self, args)
            self.m_PlayerObjects[obj.m_ID] = obj
            if obj.m_Pid == self.m_MainRPid:
                self.m_MainRole = obj
        elif etype == ENTITY_BULLET:
            obj = CBulletObj(self, args)
            self.m_BulletObjects[obj.m_ID] = obj
        elif etype == ENTITY_ENEMY:
            obj = CEnemyObj(self)
            self.m_EnemyObjects[obj.m_ID] = obj

        self.m_AllEntityObjects[obj.m_ID] = obj
        return obj

    def destroy_entity(self, obj):
        if obj.is_bullet():
            del self.m_BulletObjects[obj.m_ID]
        elif obj.is_enemy():
            del self.m_EnemyObjects[obj.m_ID]
        elif obj.is_player():
            del self.m_PlayerObjects[obj.m_ID]
            if obj.m_Pid == self.m_MainRPid:
                self.m_MainRole = None
        del self.m_AllEntityObjects[obj.m_ID]
        obj.release()

    def update_frame(self, msg):
        self.m_GSFrameNo = msg["frame_number"]
        self.update_ctrl_once()
        oplist = msg["ctrl_data"]
        for ctrl in oplist:
            pid = ctrl["pid"]
            if ctrl["action"] == ACTION_ENTER:
                pobj = self.get_player(pid)
                if pobj:
                    self.destroy_entity(pobj)
                args = ctrl["enter_info"]
                args["pid"] = pid
                self.new_player(args)
            elif ctrl["action"] == ACTION_LEAVE:
                pobj = self.get_player(pid)
                if pobj:
                    self.destroy_entity(pobj)
            elif ctrl["action"] == ACTION_ATTACK:
                pobj = self.get_player(pid)
                if pobj:
                    pobj.handle_attack(ctrl["attack_info"]["status"])
            elif ctrl["action"] == ACTION_MOVE:
                pobj = self.get_player(pid)
                if pobj:
                    #print self.m_PassTime,"player %d pos %d,%d"%(pobj.m_Pid,pobj.m_Pos[0],pobj.m_Pos[1]),"ctrl",ctrl
                    pobj.handle_move(ctrl["move_info"]["dir"],ctrl["move_info"]["status"])

            self.update_ctrl_once()

    def update_ctrl_once(self):
        if RandomInt(1,20) <= 1:
            self.create_entity(ENTITY_ENEMY)

        for id1,obj1 in self.m_BulletObjects.items():
            for id2,obj2 in self.m_EnemyObjects.items():
                if not obj1.is_dead() and not obj2.is_dead():
                    if Is2RectsCross(obj1.pos(), obj1.m_Width, obj1.m_Height, obj2.pos(), obj2.m_Width, obj2.m_Height):
                        obj1.on_hit()
                        obj2.on_hit()

        for id1,obj1 in self.m_EnemyObjects.items():
            for id2,obj2 in self.m_PlayerObjects.items():
                if not obj1.is_dead() and not obj2.is_dead():
                    if Is2RectsCross(obj1.pos(), obj1.m_Width, obj1.m_Height, obj2.pos(), obj2.m_Width, obj2.m_Height):
                        obj1.on_hit()
                        obj2.on_hit()

        for uuid,obj in self.m_AllEntityObjects.items():
            obj.update()

    def recv_frame(self, msg):
        self.m_FrameQueue.put_nowait(msg)

    def draw_world(self):
        self.m_Surface.fill(COLOR_WHITE)
        for uuid,obj in self.m_AllEntityObjects.items():
            obj.draw()
        text = self.m_ChineseFont.render("GAME_ID:%d PassTime:%f GSFrameNo:%d"%(self.m_GameID,self.m_PassTime,self.m_GSFrameNo), True, COLOR_GREEN)
        self.m_Surface.blit(text, (100,10))
        text = self.m_ChineseFont.render("HOST:%s:%d"%(self.m_RpcObj.addr[0],self.m_RpcObj.addr[1]), True, COLOR_RED)
        self.m_Surface.blit(text, (100,60))
        text = self.m_ChineseFont.render("CSRTT:%f[%f,%f,%f]MS"%(self.m_OldRTT*1000,self.m_MinRTT*1000,self.m_AvgRTT*1000,self.m_MaxRTT*1000), True, COLOR_PINK)
        self.m_Surface.blit(text, (100,110))
        text = self.m_ChineseFont.render("SCORE:%d/%d"%(self.m_CurScore,self.m_GoalScore), True, COLOR_BLUE)
        self.m_Surface.blit(text, (100,160))
        if self.m_GSRTT:
            text = self.m_ChineseFont.render("GSRTT:%f[%f,%f,%f]MS"%(self.m_GSRTT["cur_rtt"]*10.0,self.m_GSRTT["min_rtt"]*10.0,self.m_GSRTT["avg_rtt"]*10.0,self.m_GSRTT["max_rtt"]*10.0), True, COLOR_PINK)
            self.m_Surface.blit(text, (100,210))

        if self.m_GameOver:
            font = pygame.font.Font("SIMSUN.TTC",60)
            text = font.render("YOU WIN!", True, COLOR_RED)
            self.m_Surface.blit(text, (250,300))

    def main_loop(self):
        pygame.init()
        self.m_ChineseFont = pygame.font.Font("SIMSUN.TTC",30)
        self.m_Surface = pygame.display.set_mode((SCREEN_WIDTH,SCREEN_HEIGHT), 0, 32)
        clock = pygame.time.Clock()
        while True:
            if not FSM_OPEN:
                continue
            self.listen_event()
            self.update_logic()
            self.draw_world()
            pygame.display.update()
            clock.tick(FRAME_TICK)

    def init_fsm(self, msg):
        self.m_FsmInitData = msg
        self.gs2c_frame_cache_data([])

    def server_ping(self, session, is_resp):
        if is_resp:
            last_t = self.m_dRTTSessions[session]
            del self.m_dRTTSessions[session]
            dt = time.time() - last_t
            self.m_lRTTValues.append(dt)
            if len(self.m_lRTTValues) > 5:
                self.m_lRTTValues.pop(0)
            self.m_RTT = sum(self.m_lRTTValues)/len(self.m_lRTTValues)
            if abs(self.m_OldRTT - self.m_RTT) >= 0.05:
                self.m_OldRTT = self.m_RTT
                self.refresh_rtt(self.m_RTT)
        else:
            if not self.m_dRTTSessions.get(session,None):
                self.m_dRTTSessions[session] = time.time()
                self.m_RpcObj.send("c2gs_ping", {'session':session})

    def refresh_rtt(self, val):
        ti = time.time()
        dt = ti - self.m_RTTLastMS
        self.m_RTTLastMS = ti
        self.m_SumRTT = self.m_SumRTT + dt*self.m_RTT
        self.m_RTT = val
        if val > self.m_MaxRTT:
            self.m_MaxRTT = val
        if val < self.m_MinRTT:
            self.m_MinRTT = val
        dt = ti - self.m_RTTStartMS
        if dt > 0:
            self.m_AvgRTT = self.m_SumRTT/dt

    def add_score(self, score):
        self.m_CurScore += score
        if self.m_CurScore >= self.m_GoalScore:
            self.m_GameOver = True

    def gs2c_rtt_data(self, gs_data):
        self.m_GSRTT = gs_data

    def gs2c_frame_cache_data(self, frame_cache):
        msg = self.m_FsmInitData
        if not msg:
            return
        for data in frame_cache:
            self.recv_frame(data)
        if self.m_FrameQueue.qsize() >= msg["frame_cache_num"]:
            self.m_FsmInitData = None
            rndseed = msg["rndseed"]
            game_id = msg["game_id"]
            SetRndSeed(rndseed)
            self.m_GameID = game_id
            self.m_GSFsmInitTime = msg["init_time"]
            end_time = msg["timestamp"]
            dt = end_time - self.m_GSFsmInitTime
            while self.m_PassTime < dt:
                self.update_logic()

            global FSM_OPEN
            FSM_OPEN = True
