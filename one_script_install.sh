#!/bin/bash
set -e

curl -o /tmp/install_arch.sh https://raw.githubusercontent.com/ylorenzati/archinst/master/install_arch.sh
curl -o /tmp/nvme0n1.layout https://raw.githubusercontent.com/ylorenzati/archinst/master/nvme0n1.layout

chmod +x /tmp/install_arch.sh

#/bin/bash /tmp/install_arch.sh
