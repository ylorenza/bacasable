#!/bin/bash
set -e

curl -o /tmp/install_arch.sh https://raw.githubusercontent.com/ylorenza/bacasable/master/install_arch.sh
curl -o /tmp/sda.layout https://raw.githubusercontent.com/ylorenza/bacasable/master/sda.layout

chmod +x /tmp/install_arch.sh

/bin/bash /tmp/install_arch.sh


