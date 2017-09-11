Frame-Sync-Model
========
    A small game based on frame synchronization
Wiki
-----
    该项目是一个简易的方块射击游戏，服务端基于skynet，客户端基于pygame搭建,
    采用[乐观帧锁定]的同步方式,即服务端每各固定tick将该tick内收集到的所有客户端输入合包后广播给所有客户端,
    客户端收到广播包后将所有输入按顺序在本地状态机输入表现支持了断线重连和新加入玩家重建状态机的功能.
三方库
-----
    https://github.com/bttscut/pysproto.git
    https://github.com/cloudwu/skynet.git
支持平台
-------
    Linux
编译链接
-----
    sh init.sh
环境搭建
-----
    服务端:
      sh rungs.sh
    客户端:
      sh runcs.sh $pid #default 1, different terminal use different pid