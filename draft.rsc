# Базовые настройки:

/interface ethernet
set [ find default-name=ether1 ] comment=ISP1
set [ find default-name=ether2 ] comment=ISP2

/interface list
add name=WAN

/interface list member
add interface=ether1 list=WAN
add interface=ether2 list=WAN

/ip address
add address=198.51.100.6/29 interface=ether1
add address=203.0.113.6/29 interface=ether2
add address=192.168.88.254/24 interface=br-lan

/ip firewall nat
add action=masquerade chain=srcnat out-interface-list=WAN

# Создать дополнительные роутинг таблицы

[admin@MikroTik] > /routing/table/export terse
# dec/11/2021 00:50:35 by RouterOS 7.1
# software id =
#
/routing table add disabled=no fib name=rtab-1
/routing table add disabled=no fib name=rtab-2



# Добавить дефолты в новые таблицы

[admin@MikroTik] /ip/route> export terse
# dec/11/2021 00:59:52 by RouterOS 7.1
# software id =
#
/ip route add distance=251 gateway=198.51.100.1
/ip route add distance=252 gateway=203.0.113.1
/ip route add gateway=198.51.100.1 routing-table=rtab-1
/ip route add gateway=203.0.113.1 routing-table=rtab-2


# Добавить маркировки

[admin@MikroTik] /ip/firewall/mangle> export
# dec/11/2021 01:07:11 by RouterOS 7.1
# software id =
#
/ip firewall mangle
add action=mark-connection chain=prerouting connection-mark=no-mark in-interface=ether1 new-connection-mark=con-isp1 passthrough=yes
add action=mark-connection chain=prerouting connection-mark=no-mark in-interface=ether2 new-connection-mark=con-isp2 passthrough=yes
add action=mark-routing chain=prerouting connection-mark=con-isp1 in-interface-list=!WAN new-routing-mark=rtab-1 passthrough=yes
add action=mark-routing chain=prerouting connection-mark=con-isp2 in-interface-list=!WAN new-routing-mark=rtab-2 passthrough=yes
add action=mark-routing chain=output connection-mark=con-isp1 new-routing-mark=rtab-1 passthrough=yes
add action=mark-routing chain=output connection-mark=con-isp2 new-routing-mark=rtab-2 passthrough=yes


# При таких маркировках будут работать оба провайдера.
# DST-NAT так же будет работать.



# Отказоустойчивость через рекурсивные маршруты

[admin@MikroTik] /ip/route> export
# dec/11/2021 01:28:53 by RouterOS 7.1
# software id =
#
/ip route
add distance=251 gateway=198.51.100.1
add distance=252 gateway=203.0.113.1
add gateway=198.51.100.1 routing-table=rtab-1
add gateway=203.0.113.1 routing-table=rtab-2
add dst-address=4.2.2.1/32 gateway=198.51.100.1 scope=11
add dst-address=4.2.2.2/32 gateway=203.0.113.1  scope=11
add check-gateway=ping distance=10 gateway=4.2.2.1 target-scope=11
add check-gateway=ping distance=20 gateway=4.2.2.2 target-scope=11


## log check gateway
 10:29:41 firewall,info forward: in:ether3 out:ether1, src-mac 50:00:00:03:00:00, proto ICMP (type 8, code 0), 198.51.100.6->4.2.2.1, len 56
 10:29:51 firewall,info forward: in:ether3 out:ether1, src-mac 50:00:00:03:00:00, proto ICMP (type 8, code 0), 198.51.100.6->4.2.2.1, len 56
 10:30:01 firewall,info forward: in:ether3 out:ether1, src-mac 50:00:00:03:00:00, proto ICMP (type 8, code 0), 198.51.100.6->4.2.2.1, len 56
 10:30:11 firewall,info forward: in:ether3 out:ether1, src-mac 50:00:00:03:00:00, proto ICMP (type 8, code 0), 198.51.100.6->4.2.2.1, len 56
 10:30:21 firewall,info forward: in:ether3 out:ether1, src-mac 50:00:00:03:00:00, proto ICMP (type 8, code 0), 198.51.100.6->4.2.2.1, len 56
 10:30:31 firewall,info forward: in:ether3 out:ether1, src-mac 50:00:00:03:00:00, proto ICMP (type 8, code 0), 198.51.100.6->4.2.2.1, len 56

## log check gateway ISP1
10:29:41 forward: proto ICMP (type 8, code 0), 198.51.100.6->4.2.2.1,
10:29:51 forward: proto ICMP (type 8, code 0), 198.51.100.6->4.2.2.1,
10:30:01 forward: proto ICMP (type 8, code 0), 198.51.100.6->4.2.2.1,
10:30:11 forward: proto ICMP (type 8, code 0), 198.51.100.6->4.2.2.1,
10:30:21 forward: proto ICMP (type 8, code 0), 198.51.100.6->4.2.2.1,
10:30:31 forward: proto ICMP (type 8, code 0), 198.51.100.6->4.2.2.1,

####################
# VRF Изолированный!
####################

[admin@PE] > export
# dec/10/2021 23:01:21 by RouterOS 7.1
# software id =
#
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/ip vrf
add interfaces=ether3 name=vrf2
add interfaces=ether2 name=vrf1
/port
set 0 name=serial0
/ip address
add address=192.168.2.1/30 interface=ether2 network=192.168.2.0
add address=192.168.2.6/30 interface=ether3 network=192.168.2.4
/ip dhcp-client
add interface=ether1
/system identity
set name=PE


[admin@PE] > /export
# dec/13/2021 11:29:48 by RouterOS 7.1
# software id =
#
/ip vrf
add interfaces=ether3 name=vrf2
add interfaces=ether2 name=vrf1
/ip address
add address=192.168.2.1/30 interface=ether2 network=192.168.2.0
add address=192.168.2.6/30 interface=ether3 network=192.168.2.4
/ip dhcp-client
add interface=ether1
/ip route
add distance=1 dst-address=192.168.2.4/30 gateway=ether3@vrf2 routing-table=vrf1
add distance=1 dst-address=192.168.2.0/30 gateway=ether2@vrf1 routing-table=vrf2
/ip service
set ssh vrf=vrf1
/system identity
set name=PE
/tool romon
set enabled=yes



[admin@PE] > export
# dec/13/2021 11:18:15 by RouterOS 7.1
# software id =
#
/ip vrf
add interfaces=ether3 name=vrf2
add interfaces=ether2 name=vrf1
/ip address
add address=192.168.2.1/30 interface=ether2 network=192.168.2.0
add address=192.168.2.6/30 interface=ether3 network=192.168.2.4
/ip dhcp-client
add interface=ether1
/system identity
set name=PE


[admin@CE6] > export
# dec/13/2021 11:15:17 by RouterOS 6.46.8
# software id =
#
#
#
/ip address
add address=192.168.2.2/30 interface=ether1 network=192.168.2.0
/ip route
add distance=1 gateway=192.168.2.1
/system identity
set name=CE6
[admin@CE6] >
[admin@CE6] > ping count=2 192.168.2.1
  SEQ HOST                                     SIZE TTL TIME  STATUS
    0 192.168.2.1                                56  64 5ms
    1 192.168.2.1                                56  64 3ms
    sent=2 received=2 packet-loss=0% min-rtt=3ms avg-rtt=4ms max-rtt=5ms

[admin@CE6] > ping count=2 192.168.2.6
  SEQ HOST                                     SIZE TTL TIME  STATUS
    0 192.168.2.1                                84  64 3ms   net unreachable
    1 192.168.2.1                                84  64 3ms   net unreachable
    sent=2 received=0 packet-loss=100%

[admin@CE6] > ping count=2 192.168.2.5
  SEQ HOST                                     SIZE TTL TIME  STATUS
    0 192.168.2.1                                84  64 3ms   net unreachable
    1 192.168.2.1                                84  64 3ms   net unreachable
    sent=2 received=0 packet-loss=100%

[admin@CE6] >


[admin@CE7] > /export
# dec/13/2021 10:59:34 by RouterOS 6.46.8
# software id =
#
#
#
/ip address
add address=192.168.2.5/30 interface=ether1 network=192.168.2.4
/ip route
add distance=1 gateway=192.168.2.6
/system identity
set name=CE7
[admin@CE7] > /ping count=2 192.168.2.6
  SEQ HOST                                     SIZE TTL TIME  STATUS
    0 192.168.2.6                                56  64 2ms
    1 192.168.2.6                                56  64 2ms
    sent=2 received=2 packet-loss=0% min-rtt=2ms avg-rtt=2ms max-rtt=2ms

[admin@CE7] > /ping count=2 192.168.2.1
  SEQ HOST                                     SIZE TTL TIME  STATUS
    0 192.168.2.6                                84  64 2ms   net unreachable
    1 192.168.2.6                                84  64 2ms   net unreachable
    sent=2 received=0 packet-loss=100%

[admin@CE7] > /ping count=2 192.168.2.2
  SEQ HOST                                     SIZE TTL TIME  STATUS
    0 192.168.2.6                                84  64 2ms   net unreachable
    1 192.168.2.6                                84  64 5ms   net unreachable
    sent=2 received=0 packet-loss=100%

####################
# route leaks
####################

[admin@CE6] > /export
# dec/13/2021 11:37:58 by RouterOS 6.46.8
# software id =
#
#
#
/ip address
add address=192.168.2.2/30 interface=ether1 network=192.168.2.0
/ip route
add distance=1 gateway=192.168.2.1
/system identity
set name=CE6
[admin@CE6] > ping count=2 192.168.2.1
  SEQ HOST                                     SIZE TTL TIME  STATUS
    0 192.168.2.1                                56  64 4ms
    1 192.168.2.1                                56  64 2ms
    sent=2 received=2 packet-loss=0% min-rtt=2ms avg-rtt=3ms max-rtt=4ms

[admin@CE6] > ping count=2 192.168.2.6
  SEQ HOST                                     SIZE TTL TIME  STATUS
    0 192.168.2.6                                             timeout
    1 192.168.2.6                                             timeout
    sent=2 received=0 packet-loss=100%

[admin@CE6] > ping count=2 192.168.2.5
  SEQ HOST                                     SIZE TTL TIME  STATUS
    0 192.168.2.5                                56  63 8ms
    1 192.168.2.5                                56  63 7ms
    sent=2 received=2 packet-loss=0% min-rtt=7ms avg-rtt=7ms max-rtt=8ms

[admin@CE6] >

####################
# vrf vpn
####################

[admin@PE] /routing/bgp/vpn> add
copy-from      export-route-targets  label-allocation-policy  vrf
disabled       import-filter         redistribute
export-filter  import-route-targets  route-distinguisher



####################
# vrf mngt
####################

[admin@PE] /ip/service> set ssh vrf=vrf1
[admin@PE] /ip/service> pri
Flags: X, I - INVALID
Columns: NAME, PORT, CERTIFICATE, VRF
#   NAME     PORT  CERTIFICATE  VRF
0 X telnet     23               main
1 X ftp        21
2 X www        80               main
3   ssh        22               vrf1
4 X www-ssl   443  none         main
5 X api      8728               main
6   winbox   8291               main
7 X api-ssl  8729  none         main

[admin@CE6] > sys ssh 192.168.2.1
password:

  MMM      MMM       KKK                          TTTTTTTTTTT      KKK
  MMMM    MMMM       KKK                          TTTTTTTTTTT      KKK
  MMM MMMM MMM  III  KKK  KKK  RRRRRR     OOOOOO      TTT     III  KKK  KKK
  MMM  MM  MMM  III  KKKKK     RRR  RRR  OOO  OOO     TTT     III  KKKKK
  MMM      MMM  III  KKK KKK   RRRRRR    OOO  OOO     TTT     III  KKK KKK
  MMM      MMM  III  KKK  KKK  RRR  RRR   OOOOOO      TTT     III  KKK  KKK

  MikroTik RouterOS 7.1 (c) 1999-2021       https://www.mikrotik.com/

Press F1 for help

[admin@PE] >


[admin@CE7] > sys ssh 192.168.2.6
connectHandler: Connection refused

Welcome back!


# Route leaks не помогли.

[admin@PE] /ip/route> export
# dec/10/2021 23:22:29 by RouterOS 7.1
# software id =
#
/ip route
add dst-address=192.168.1.0/24 gateway=ether1@main routing-table=vrf1

[admin@PE] /ip/route> pri detail
Flags: D - dynamic; X - disabled, I - inactive, A - active; c - connect, s - static, r - rip, b - bgp, o - ospf, d - dhcp, v - vpn, m - modem, y - copy; H - hw-offloaded; + - ecmp
   DAd   dst-address=0.0.0.0/0 routing-table=main pref-src="" gateway=192.168.1.11 immediate-gw=192.168.1.11%ether1 distance=1 scope=30 target-scope=10 vrf-interface=ether1 suppress-hw-offload=no

   DAc   dst-address=192.168.1.0/24 routing-table=main gateway=ether1 immediate-gw=ether1 distance=0 scope=10 suppress-hw-offload=no local-address=192.168.1.186%ether1

 0  As   dst-address=192.168.1.0/24 routing-table=vrf1 pref-src="" gateway=ether1 immediate-gw=ether1 distance=1 scope=30 target-scope=10 suppress-hw-offload=no

   DAc   dst-address=192.168.2.0/30 routing-table=vrf1 gateway=ether2@vrf1 immediate-gw=ether2 distance=0 scope=10 suppress-hw-offload=no local-address=192.168.2.1%ether2@vrf1

   DAc   dst-address=192.168.2.4/30 routing-table=vrf2 gateway=ether3@vrf2 immediate-gw=ether3 distance=0 scope=10 suppress-hw-offload=no local-address=192.168.2.6%ether3@vrf2







# vrf internet

/ip vrf
add interfaces=ether1 name=vrf1
add interfaces=ether2 name=vrf2

/ip address
add address=10.51.100.6/29 interface=ether1
add address=10.51.100.6/29 interface=ether2

/ip route
add check-gateway=ping distance=251 dst-address=0.0.0.0/0 gateway=10.51.100.1@vrf1 routing-table=main
add check-gateway=ping distance=252 dst-address=0.0.0.0/0 gateway=10.51.100.1@vrf2 routing-table=main
add dst-address=192.168.88.0/24 gateway=br-lan routing-table=vrf1
add dst-address=192.168.88.0/24 gateway=br-lan routing-table=vrf2
