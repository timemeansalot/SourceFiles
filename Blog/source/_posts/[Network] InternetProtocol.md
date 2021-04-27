---
title: 常见网络协议格式
date: 2021-04-27 18:08:36
tags: Network
---



各层网络协议格式

<!--more-->

[[_TOC_]]

## ETAG (802.1BR)

```text
// ETAG, ETYP=0x893f
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// | pcp |d| igr_ecid_base         | r | g | ecid_base             |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// | igr_ecid_ext  | ecid_ext      |
// +---------------+---------------+
// pcp:           PCP
// d:             DEI
// igr_ecid_base: ingress extended port id       - base
// r:             reserved
// g:             group
// ecid_base:     extended port id               - base
// igr_ecid_ext:  ingress extended port id       - extension
// ecid_ext:      extended port id               - extension
```

```text
// VN-TAG, ETYP=0x8926 (cisco proprietary, obsolete)
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |d|p|         dst_vif           |l|v|ver|       src_vif         |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// d:        direction                  (0: upstream; 1: downstream       )
// p:        pointer                    (0: unicast;  1: multicast        )
// dst_vif:  destination virtual I/F ID (p2p: 12-bit; p2mp: 14-bit        )
// l:        loop                       (set when goes back to source vNIC)
// v:        vSL                        (Cisco proprietary application    )
// ver:      version                    (set to 0                         )
// src_vif:  source virtual I/F ID
```

## SNAP

```text
// TYPE_LENGTH <= 1500
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |             len               |     dsap      |    ssap       |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |  control    |                    protocol id                  | 
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// SNAP, 8-byte of overhead {len[15:0], 0xaa, 0xaa, 0x03, 0x00, 0x00, 0x00}
// SNAP requires DSAP=0xaa, SSAP=0xaa, control=0x03, protocol_id=0x00_00_00
```

## VLAN tag, VEPA tag

```text
// 1Q VLAN, ETYP=0x8100; QinQ STAG, ETYP=0x88a8; VEPA, ETYP=0x88a8
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// | pcp |d|         vid           |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

## ARP

```text
// ARP, ETYP=0x0806
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |              hrd              |              pro              | // hardware type | protocol type
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |      hln      |      pln      |              op               | // length of hardware address | length of protocol address | operator
// +---------------+---------------+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |              sha_w0           |             sha_w1            | // hardware address of the sender
// +---------------+---------------+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |              sha_w1           |               spa             | // IP address of the sender 
// +---------------+---------------+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |              spa              |             tha_w0            | // hardware address of the receiver
// +---------------+---------------+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |                             tha_w1                            |
// +---------------+---------------+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |                             tpa                               | // IP address of the receiver
// +---------------+---------------+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

## PPPoE

```text
// PPPoE session stage, ETYP=0x8864
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |  VER  | TYPE  |      CODE     |          SESSION_ID           |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |            LENGTH             |           payload             ~
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

## IPv4

http://tools.ietf.org/html/rfc791
Sep 1981
INTERNET PROTOCOL

```text
// IPv4, ETYP=0x0800
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |Version|  IHL  |Type of Service|          Total Length         |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |         Identification        |Flags|      Fragment Offset    |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |  Time to Live |    Protocol   |         Header Checksum       |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |                       Source Address                          |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |                    Destination Address                        |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

## IPv6

http://tools.ietf.org/html/rfc2460
Dec 1998
Internet Protocol, Version 6 (IPv6) Specification

```text
// IPv6, ETYP=0x86dd
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |Version| Traffic Class |                   Flow Label          |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |         Payload Length        |  Next Header  |   Hop Limit   |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |                                                               |
// +                                                               +
// |                                                               |
// +                         Source Address                        +
// |                                                               |
// +                                                               +
// |                                                               |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
// |                                                               |
// +                                                               +
// |                                                               |
// +                      Destination Address                      +
// |                                                               |
// +                                                               +
// |                                                               |
// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

## IPv6 next header

http://tools.ietf.org/html/rfc6564
Apr 2012
A Uniform Format for IPv6 Extension Headers

```text
// IPv6 next header// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |  Next Header  |  Hdr Ext Len  |                               |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+                               +// |                                                               |// .                                                               .// .                  Header Specific Data                         .// .                                                               .// |                                                               |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// Next Header          8-bit selector.  Identifies the type of header//                      immediately following the extension header.//                      Uses the same values as the IPv4 Protocol field//                      [IANA_IP_PARAM].// Hdr Ext Len          8-bit unsigned integer.  Length of the extension//                      header in 8-octet units, not including the first//                      8 octets.// Header Specific      Variable length.  Fields specific to the// Data                 extension header.
```

## GRE

http://tools.ietf.org/html/rfc1701
Oct 1994
Generic Routing Encapsulation (GRE)

http://tools.ietf.org/html/rfc2784
Mar 2000
Generic Routing Encapsulation (GRE)

http://tools.ietf.org/html/rfc7637
Sep 2015
NVGRE: Network Virtualization Using Generic Routing Encapsulation

```text
// GRE// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |C| |K|S| Reserved0       | Ver |   Protocol Type               |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |      Checksum (optional)      |       Reserved1 (Optional)    |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |               Virtual Subnet ID (VSID)        |    FlowID     |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |                    Sequence Number (optional)                 |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// C=1: qualify Checksum// K=1: qualify {VSID, FlowID} // S=1: sequence number present
```

## MPLS

http://tools.ietf.org/html/rfc3032
Jan 2001
MPLS Label Stack Encoding

http://tools.ietf.org/html/rfc4023
Mar 2005
Encapsulating MPLS in IP or Generic Routing Encapsulation (GRE)

https://tools.ietf.org/html/rfc8365
Mar 2018
A Network Virtualization Overlay Solution Using Ethernet VPN (EVPN)

- https://172.16.2.224/mprojects/mnm/-/blob/master/shr/mnm_mpls.h
- https://172.16.2.224/mprojects/mnm/-/blob/master/shr/mnm_mpls.cc

```text
// MPLS, ETYP=0x8847// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ Label// |                Label                  | Exp |S|       TTL     | Stack// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ Entry//                     Label:  Label Value, 20 bits//                     Exp:    Experimental Use, 3 bits//                     S:      Bottom of Stack, 1 bit//                     TTL:    Time to Live, 8 bits
```

## ERSPAN type II / III

https://tools.ietf.org/html/draft-foschiano-erspan-03
February 2017
Cisco Systems' Encapsulated Remote Switch Port Analyzer (ERSPAN)

```text
// ERSPAN type II, GRE "protocol type" is 0x22eb// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |  Ver  |          VLAN         | COS | En|T|    Session ID     |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |      Reserved         |                  Index                |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

```text
// ERSPAN type III, GRE "protocol type" is 0x88be// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |  Ver  |          VLAN         | COS |BSO|T|     Session ID    |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |                          Timestamp                            |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |             SGT               |P|    FT   |   Hw ID   |D|Gra|O|// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+////    Platform Specific SubHeader (8 octets, optional)// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |  Platf ID |               Platform Specific Info              |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |                  Platform Specific Info                       |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

## SCTP

https://tools.ietf.org/html/rfc4960
September 2007
Stream Control Transmission Protocol

```text
// SCTP// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |     Source Port Number        |     Destination Port Number   |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |                      Verification Tag                         |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |                           Checksum                            |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

## UDP

https://tools.ietf.org/html/rfc768
28 August 1980
User Datagram Protocol

```text
// UDP, IP_PROTOCOL=0x11// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |           Source Port             |      Destination Port     |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |              Length               |            Checksum       |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

## TCP

https://tools.ietf.org/html/rfc793
September 1981
TRANSMISSION CONTROL PROTOCOL

```text
// TCP, IP_PROTOCOL=0x6// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |          Source Port          |       Destination Port        |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |                        Sequence Number                        |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |                    Acknowledgment Number                      |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |  Data |     |N|C|E|U|A|P|R|S|F|                               |// | Offset| RSVD| |W|C|R|C|S|S|Y|I|            Window             |// |       |     |S|R|E|G|K|H|T|N|N|                               |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |           Checksum            |         Urgent Pointer        |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

## ICMP

https://tools.ietf.org/html/rfc792
INTERNET CONTROL MESSAGE PROTOCOL
September 1981

```text
//  ICMP, IP_PROTOCOL=0x1//  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+//  |     Type      |     Code      |          Checksum             |//  +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+//  |                                                               |//  +                         Message Body                          +//  |                                                               |
```

## VXLAN base

http://tools.ietf.org/html/rfc7348
Aug 2014
Virtual eXtensible Local Area Network (VXLAN): A Framework for Overlaying Virtualized Layer 2 Networks over Layer 3 Networks

```text
// VXLAN, UDP destination port=4789 // +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |R|R|R|R|I|R|R|R|            Reserved                           |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |                VXLAN Network Identifier (VNI) |   Reserved    |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

## VXLAN GPE

https://tools.ietf.org/html/draft-ietf-nvo3-vxlan-gpe-09
December 5, 2019
Generic Protocol Extension for VXLAN

```text
// VXLAN GPE, UDP destination port=4790 // Next protocol: IPv4 (1), IPv6 (2), Ethernet (3), NSH (4)// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |R|R|R|R|I|P|R|O|Ver|   Reserved                |Next Protocol  |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |                VXLAN Network Identifier (VNI) |   Reserved    |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

## NSH

https://tools.ietf.org/html/rfc8300
January 2018
Network Service Header (NSH)

```text
// NSH base header// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |Ver|O|U|    TTL    |   Length  |U|U|U|U|MD Type| Next Protocol |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+//// Service Path Header// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |          Service Path Identifier (SPI)        | Service Index |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

## IOAM

https://tools.ietf.org/html/draft-ietf-ippm-ioam-data-10
July 13, 2020
Data Fields for In-situ OAM

```text
// IOAM over GRE// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+<-+// |     Type      |   IOAM HDR len|        Next Protocol          |  |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+IOAM// |         IOAM-Trace-Type       |NodeLen|  Flags  | Octets-left |Trace// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+<-+  // IOAM over VXLAN GPE// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+--+// |      Type     |   IOAM HDR len|    Reserved   | Next Protocol |  |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+IOAM// |         IOAM-Trace-Type       |NodeLen|  Flags  | Octets-left |Trace// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+<-+// IOAM over GENEVE// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+--+// |  Option Class = IOAM_Trace    |  Type (incr.) |R|R|R| Length  |  |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ IOAM// |        IOAM-Trace-Type        |NodeLen|  Flags  | Max Length  | Trace// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+<-+// IOAM over HBH// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |  Option Type  |  Opt Data Len |         Reserved (MBZ)        |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+<-+// |        IOAM-Trace-Type        |NodeLen|  Flags  | Max Length  |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+  
```

## AH header

http://tools.ietf.org/html/rfc4302
Dec 2005
IP Authentication Header

```text
// AH// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// | Next Header   |  Payload Len  |          RESERVED             |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |                 Security Parameters Index (SPI)               |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |                    Sequence Number Field                      |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |                                                               |// +                Integrity Check Value-ICV (variable)           |// |                                                               |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

## IFA 2.0

https://tools.ietf.org/html/draft-kumar-ippm-ifa-02
April 24, 2020
Inband Flow Analyzer

```text
// IFA Header// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// | Ver=2 |  GNS  |NextHdr = IP_xx|R|R|R|M|T|I|T|C|   Max Length  |// |       |       |               | | | |F|S| |A| |               |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

```text
// IFA Meta Header// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// | Request Vector| Action Vector |   Hop Limit   | Current Length|// |               |L|C|R|R|R|R|R|R|               |               |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

```text
// IFA Metadata// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |  LNS  |                     Device ID                         |// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+// |                                                               |// ~                LNS/GNS defined metadata (contd)               ~// .                                                               .// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

