# Emulating SNMP OIDs

I was recently commissioned to add value to a Nagios plugin. This plugin was [check_eigrp](link). The client required the plugin to be extended to support SNMP version 3. This is all fine and good, except for the fact that I don't have access to any networking equipment that I could test against.

That's where snmpd comes in. So if you've ever wanted to emulate SNMP OIDs of devices you don't have access to, buckle up because you're in for an exciting ride\*.

***\**** *disclaimer: there is nothing exciting about this article.*
