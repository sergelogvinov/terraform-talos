[
{ "op": "replace", "path": "/machine/network/interfaces", "value": [
        {
          "interface": "eth0",
          "dhcp": true
        },
        {
          "interface": "eth0",
          "cidr": "${ipv6_address}/64",
          "routes": [
            {
              "network": "::/0",
              "gateway": "fe80::1",
              "metric": 1024
            }
          ]
        },
        {
          "interface": "eth1",
          "dhcp": true
        },
        {
          "interface": "dummy0",
          "cidr": "169.254.2.53/32"
        },
        {
          "interface": "dummy0",
          "cidr": "fd00::169:254:2:53/128"
        }
      ]
}
]
