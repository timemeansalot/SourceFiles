---
title: internet_protocol_format
date: 2021-03-23 13:25:44
tags: network
---



My Notes about internet frame format like `ethernet`、`TCP/IP`



[[_TOC_]]

<!--more-->

# L2 LinkLayer

## Ethernet 2

DMAC 48b;SMAC 48b



ethernet type: 16b

## 802.1q/ad

tag format:

![image-20210323092527183](https://i.loli.net/2021/03/23/LxeoRtiha7EB9DO.png)

1. TPID 16b: tag protocol identifier, always 0x8100 to identify it's a 802.1q tagged frame
2. TCI 16b: tag control information
   - PCP 3b: priority code point, identify frame priority level
   - DEI 1b: drop eligible indicator, to indicate frames eligible to be dropped in the presence of congestion
   - VID 12b: VLAN identifier

802.1ad introduced the concept of double tagging: there is two tags: 0x88a8, 0x8100

## 802.3

## LLC

## ARP

## MPLS

**Multiprotocol Label Switching** (**MPLS**) is a routing technique in [telecommunications networks](https://en.wikipedia.org/wiki/Telecommunications_network) that directs data from one [node](https://en.wikipedia.org/wiki/Node_(networking)) to the next `based on short path labels rather than long network addresses`, thus avoiding complex lookups in a [routing table](https://en.wikipedia.org/wiki/Routing_table) and speeding traffic flows

![image-20210323105006216](https://i.loli.net/2021/03/23/W9tnLeNuXxIqwM6.png)

- A 20-bit label value. A label with the value of 1 represents the [router alert label](https://en.wikipedia.org/wiki/Router_alert_label).
- a 3-bit *Traffic Class* field for QoS ([quality of service](https://en.wikipedia.org/wiki/Quality_of_service)) priority and ECN ([Explicit Congestion Notification](https://en.wikipedia.org/wiki/Explicit_Congestion_Notification)). Prior to 2009 this field was called EXP.[[9\]](https://en.wikipedia.org/wiki/Multiprotocol_Label_Switching#cite_note-9)
- a 1-bit *bottom of stack* flag. If this is set, it signifies that the current label is the last in the stack.
- an 8-bit TTL ([time to live](https://en.wikipedia.org/wiki/Time_to_live)) field.

# L3 NetworkLayer

## IPv4

packet format：

![image-20210323093146792](https://i.loli.net/2021/03/23/O4kQyCZr721e9Es.png)



1. version(4b): always equal to 4 to identify its an ipv4 datagram
2. IHL(4b): size of IPv4 header, unit is 4B; 
3. DSCP(6b): Typs of service
4. ECN(2b): explicit congestion notification
5. Totol Lenght(16b): entire packet size in bytes, unit is 1B
6. Identification(16b): identify the group of fragments of a single IP datagram, IP message can be splited to fragments when transferring on L2
7. Flags(3b): A three-bit field follows and is used to control or identify fragments
8. Fragment Offset(12b): The fragment offset field is measured in units of eight-byte blocks , unit is 8B
9. TTL(8b): time to live, prevent datagrams from persisting
10. Protocol(8b): identify witch Transferring protocol is running. 0x11 for UDP, 0x06 for TCP
11. Header Checksum(16b): is used for error-checking of the header
12. Options: often not used and should be an integer multiple of 4B

## IPv6

packet format: 

![image-20210323094523253](https://i.loli.net/2021/03/23/cEn4uQxSar6J5Hy.png)

***Version* (4 bits)**

The constant 6 (bit sequence `0110`).

***Traffic Class* (6+2 bits)**

The bits of this field hold two values. The six most-significant bits hold the [differentiated services field](https://en.wikipedia.org/wiki/Differentiated_services_field) (DS field), which is used to classify packets.[[2\]](https://en.wikipedia.org/wiki/IPv6_packet#cite_note-rfc2474-2)[[3\]](https://en.wikipedia.org/wiki/IPv6_packet#cite_note-rfc3260-3) Currently, all standard DS fields end with a '0' bit. Any DS field that ends with two '1' bits is intended for local or experimental use.[[4\]](https://en.wikipedia.org/wiki/IPv6_packet#cite_note-rfc4727-4)

The remaining two bits are used for [Explicit Congestion Notification](https://en.wikipedia.org/wiki/Explicit_Congestion_Notification) (ECN);[[5\]](https://en.wikipedia.org/wiki/IPv6_packet#cite_note-rfc3168-5) priority values subdivide into ranges: traffic where the source provides congestion control and non-congestion control traffic.

***Flow Label* (20 bits)**

A high-entropy identifier of a flow of packets between a source and destination. A flow is a group of packets, e.g., a TCP session or a media stream. The special flow label 0 means the packet does not belong to any flow (using this scheme). An older scheme identifies flow by source address and port, destination address and port, protocol (value of the last *Next Header* field).[[6\]](https://en.wikipedia.org/wiki/IPv6_packet#cite_note-rfc6437-6) It has further been suggested that the flow label be used to help detect spoofed packets.[[7\]](https://en.wikipedia.org/wiki/IPv6_packet#cite_note-7)

***Payload Length* (16 bits)**

The size of the payload in octets, including any extension headers. The length is set to zero when a *Hop-by-Hop* extension header carries a [Jumbo Payload](https://en.wikipedia.org/wiki/IPv6_packet#Jumbogram) option.[[8\]](https://en.wikipedia.org/wiki/IPv6_packet#cite_note-rfc2675-8)

***Next Header* (8 bits)**

Specifies the type of the next header. This field usually specifies the [transport layer](https://en.wikipedia.org/wiki/Transport_layer) protocol used by a packet's payload. When extension headers are present in the packet this field indicates which extension header follows. The values are shared with those used for the IPv4 protocol field, as both fields have the same function (see [List of IP protocol numbers](https://en.wikipedia.org/wiki/List_of_IP_protocol_numbers)).

***Hop Limit* (8 bits)**

Replaces the [time to live](https://en.wikipedia.org/wiki/Time_to_live) field in IPv4. This value is decremented by one at each forwarding node and the packet is discarded if it becomes 0. However, the destination node should process the packet normally even if received with a hop limit of 0.

***Source Address* (128 bits)**

The unicast [IPv6 address](https://en.wikipedia.org/wiki/IPv6_address) of the sending node.

***Destination Address* (128 bits)**

The IPv6 unicast or multicast address of the destination node(s).

# L4 TransportLayer

## UDP

datagram format:

![image-20210323101047873](https://i.loli.net/2021/03/23/Kwc3TmjHFEuQoy4.png)

**Source port number**

This field identifies the sender's port, when used, and should be assumed to be the port to reply to if needed. If not used, it should be zero. If the source host is the client, the port number is likely to be an ephemeral port number. If the source host is the server, the port number is likely to be a [well-known port](https://en.wikipedia.org/wiki/Well-known_port) number.[[4\]](https://en.wikipedia.org/wiki/User_Datagram_Protocol#cite_note-forouzan-4)

**Destination port number**

This field identifies the receiver's port and is required. Similar to source port number, if the client is the destination host then the port number will likely be an ephemeral port number and if the destination host is the server then the port number will likely be a well-known port number.[[4\]](https://en.wikipedia.org/wiki/User_Datagram_Protocol#cite_note-forouzan-4)

**Length**

This field specifies the length `in bytes` of the UDP header and UDP data. The minimum length is 8 bytes, the length of the header. The field size sets a theoretical limit of 65,535 bytes (8 byte header + 65,527 bytes of data) for a UDP datagram. However the actual limit for the data length, which is imposed by the underlying [IPv4](https://en.wikipedia.org/wiki/IPv4) protocol, is 65,507 bytes (65,535 − 8 byte UDP header − 20 byte [IP header](https://en.wikipedia.org/wiki/IPv4_header)).[[4\]](https://en.wikipedia.org/wiki/User_Datagram_Protocol#cite_note-forouzan-4)

Using IPv6 [jumbograms](https://en.wikipedia.org/wiki/Jumbogram) it is possible to have UDP datagrams of size greater than 65,535 bytes.[[5\]](https://en.wikipedia.org/wiki/User_Datagram_Protocol#cite_note-5) [RFC](https://en.wikipedia.org/wiki/RFC_(identifier)) [2675](https://tools.ietf.org/html/rfc2675) specifies that the length field is set to zero if the length of the UDP header plus UDP data is greater than 65,535.

**Checksum**

The [checksum](https://en.wikipedia.org/wiki/Checksum) field may be used for error-checking of the header and data. This field is optional in IPv4, and mandatory in IPv6.[[6\]](https://en.wikipedia.org/wiki/User_Datagram_Protocol#cite_note-rfc2460-6) The field carries all-zeros if unused.[[7\]](https://en.wikipedia.org/wiki/User_Datagram_Protocol#cite_note-rfc768-7)

## TCP

tcp segment header format

![image-20210323101614270](https://i.loli.net/2021/03/23/3vy8Gn6QpfLNOe1.png)

- **Source port (16 bits)**

  Identifies the sending port.

- **Destination port (16 bits)**

  Identifies the receiving port.

- **Sequence number (32 bits)**

  Has a dual role:If the SYN flag is set (1), then this is the initial sequence number. The sequence number of the actual first data byte and the acknowledged number in the corresponding ACK are then this sequence number plus 1.If the SYN flag is clear (0), then this is the accumulated sequence number of the first data byte of this segment for the current session.

- **Acknowledgment number (32 bits)**

  If the ACK flag is set then the value of this field is the next sequence number that the sender of the ACK is expecting. This acknowledges receipt of all prior bytes (if any). The first ACK sent by each end acknowledges the other end's initial sequence number itself, but no data.

- **Data offset (4 bits)**

  Specifies the size of the TCP header in 32-bit [words](https://en.wikipedia.org/wiki/Word_(computer_architecture)). The minimum size header is 5 words and the maximum is 15 words thus giving the minimum size of 20 bytes and maximum of 60 bytes, allowing for up to 40 bytes of options in the header. This field gets its name from the fact that it is also the offset from the start of the TCP segment to the actual data.

- **Reserved (3 bits)**

  For future use and should be set to zero.

- **Flags (9 bits)**

  Contains 9 1-bit flags (control bits) as follows:NS (1 bit): ECN-nonce - concealment protection[[a\]](https://en.wikipedia.org/wiki/Transmission_Control_Protocol#cite_note-10)CWR (1 bit): Congestion window reduced (CWR) flag is set by the sending host to indicate that it received a TCP segment with the ECE flag set and had responded in congestion control mechanism.[[b\]](https://en.wikipedia.org/wiki/Transmission_Control_Protocol#cite_note-added3168-11)ECE (1 bit): ECN-Echo has a dual role, depending on the value of the SYN flag. It indicates:If the SYN flag is set (1), that the TCP peer is [ECN](https://en.wikipedia.org/wiki/Explicit_Congestion_Notification) capable.If the SYN flag is clear (0), that a packet with Congestion Experienced flag set (ECN=11) in the IP header was received during normal transmission.[[b\]](https://en.wikipedia.org/wiki/Transmission_Control_Protocol#cite_note-added3168-11) This serves as an indication of network congestion (or impending congestion) to the TCP sender.URG (1 bit): Indicates that the Urgent pointer field is significantACK (1 bit): Indicates that the Acknowledgment field is significant. All packets after the initial SYN packet sent by the client should have this flag set.PSH (1 bit): Push function. Asks to push the buffered data to the receiving application.RST (1 bit): Reset the connectionSYN (1 bit): Synchronize sequence numbers. Only the first packet sent from each end should have this flag set. Some other flags and fields change meaning based on this flag, and some are only valid when it is set, and others when it is clear.FIN (1 bit): Last packet from sender

- **Window size (16 bits)**

  The size of the *receive window*, which specifies the number of window size units[[c\]](https://en.wikipedia.org/wiki/Transmission_Control_Protocol#cite_note-12) that the sender of this segment is currently willing to receive.[[d\]](https://en.wikipedia.org/wiki/Transmission_Control_Protocol#cite_note-13) (See [§ Flow control](https://en.wikipedia.org/wiki/Transmission_Control_Protocol#Flow_control) and [§ Window scaling](https://en.wikipedia.org/wiki/Transmission_Control_Protocol#Window_scaling).)

- **Checksum (16 bits)**

  The 16-bit [checksum](https://en.wikipedia.org/wiki/Checksum) field is used for error-checking of the TCP header, the payload and an IP pseudo-header. The pseudo-header consists of the [source IP address](https://en.wikipedia.org/wiki/IPv4#Source_address), the [destination IP address](https://en.wikipedia.org/wiki/IPv4#Destination_address), the [protocol number](https://en.wikipedia.org/wiki/List_of_IP_protocol_numbers) for the TCP protocol (6) and the length of the TCP headers and payload (in bytes).

- **Urgent pointer (16 bits)**

  If the URG flag is set, then this 16-bit field is an offset from the sequence number indicating the last urgent data byte.

- **Options (Variable 0–320 bits, in units of 32 bits)**

  The length of this field is determined by the *data offset* field. Options have up to three fields: Option-Kind (1 byte), Option-Length (1 byte), Option-Data (variable). The Option-Kind field indicates the type of option and is the only field that is not optional. Depending on Option-Kind value, the next two fields may be set. Option-Length indicates the total length of the option, and Option-Data contains data associated with the option, if applicable. For example, an Option-Kind byte of 1 indicates that this is a no operation option used only for padding, and does not have an Option-Length or Option-Data fields following it. An Option-Kind byte of 0 marks the end Of options, and is also only one byte. An Option-Kind byte of 2 is used to indicate Maximum Segment Size option, and will be followed by an Option-Length byte specifying the length of the MSS field. Option-Length is the total length of the given options field, including Option-Kind and Option-Length fields. So while the MSS value is typically expressed in two bytes, Option-Length will be 4. As an example, an MSS option field with a value of 0x05B4 is coded as (0x02 0x04 0x05B4) in the TCP options section.

  Some options may only be sent when SYN is set; they are indicated below as `[SYN]`. Option-Kind and standard lengths given as (Option-Kind, Option-Length).

# L5ApplicationLayer

