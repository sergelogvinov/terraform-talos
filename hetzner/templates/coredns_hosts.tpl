data:
  hosts: |
    # static hosts
    169.254.2.53        dns.local
    # terraform
%{ for node in masters ~}
    ${format("%-24s",node.ipv4_address)} ${node.name}
    ${format("%-24s",node.ipv6_address)} ${node.name}
%{ endfor ~}
%{ for node in web ~}
    ${format("%-24s",node.ipv4_address)} ${node.name}
    ${format("%-24s",node.ipv6_address)} ${node.name}
%{ endfor ~}
