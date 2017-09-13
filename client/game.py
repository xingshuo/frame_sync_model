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
                self.m_Pos[1] = self.m_Pos[1] - self.m_Speed
            elif self.m_Dir == DIR_DOWN:
                self.m_Pos[1] = self.m_Pos[1] + self.m_Speed
            elif self.m_Dir == DIR_LEFT:
                self.m_Pos[0] = self.m_Pos[0] - self.m_Speed
            elif self.m_Dir == DIR_RIGHT:
                self.m_Pos[0] = self.m_Pos[0] + self.m_Speed

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
        self.m_Blood = 1000
        super(CPlayerObj,self).__init__(gobj)

    def name(self):
        return u"%s[%d,%d] %d"%(self.m_Name,self.m_Pos[0],self.m_Pos[1], self.m_GameObj.m_GameID)

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
        self.m_CurScore = 0
        self.m_GoalScore = 1000
        self.m_GameOver = False

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
        if self.m_GameOver:
            return
        if RandomInt(1,10) <= 2:
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
                    pobj.handle_move(ctrl["move_info"]["dir"],ctrl["move_info"]["status"])

    def draw_world(self):
        self.m_Surface.fill(COLOR_WHITE)
        for uuid,obj in self.m_AllEntityObjects.items():
            obj.draw()

        text = self.m_ChineseFont.render("RTT:%fMS"%(self.m_RTT*1000), True, COLOR_RED)
        self.m_Surface.blit(text, (600,50))
        text = self.m_ChineseFont.render("SCORE:%d/%d"%(self.m_CurScore,self.m_GoalScore), True, COLOR_BLUE)
        self.m_Surface.blit(text, (600,100))
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
        rndseed = msg["rndseed"]
        game_id = msg["game_id"]
        SetRndSeed(rndseed)
        self.m_GameID = game_id
        self.m_FSMInitTime = msg["init_time"]
        end_time = msg["timestamp"]
        dt = end_time - self.m_FSMInitTime
        frame_cache = msg["frame_cache"]
        sum_time = 0
        while sum_time < dt:
            self.update_logic()
            sum_time += 100.0/FRAME_TICK
            while len(frame_cache) > 0:
                data = frame_cache[0]
                if data["timestamp"] - self.m_FSMInitTime < sum_time:
                    self.update_frame(data)
                    frame_cache.pop(0)
                else:
                    break

        global FSM_OPEN
        FSM_OPEN = True

    def server_ping(self, session, is_resp):
        if is_resp:
            last_t = self.m_dRTTSessions[session]
            del self.m_dRTTSessions[session]
            dt = time.time() - last_t
            self.m_lRTTValues.append(dt)
            if len(self.m_lRTTValues) > 5:
                self.m_lRTTValues.pop(0)
            self.m_RTT = sum(self.m_lRTTValues)/len(self.m_lRTTValues)
        else:
            self.m_dRTTSessions[session] = time.time()
            self.m_RpcObj.send("c2gs_ping", {'session':session})

    def add_score(self, score):
        self.m_CurScore += score
        if self.m_CurScore >= self.m_GoalScore:
            self.m_GameOver = True