#!/bin/bash
# Generate /etc/issue.net (SSH pre-login banner)
# Called by salt state or cron - outputs to stdout
# pastel goth aesthetic - twilite theme

cat << 'EOF'

[38;2;217;96;168m       .  *  .    *   .  *  .    *   .  *  .    *   .  *  .
[38;2;232;120;192m   *       .    *        .    *       .    *        .
[38;2;217;96;168m
[38;2;255;121;198m                      ~ cozy-salt ~
[38;2;112;201;221m                    a gentle haunting
[38;2;217;96;168m
[38;2;216;216;216m                 .---.      [38;2;232;120;192m  ,
[38;2;216;216;216m                / . . \    [38;2;255;121;198m'(&) [38;2;232;120;192m,
[38;2;216;216;216m                \  ^  /   [38;2;232;120;192m(&)[38;2;112;201;221m'[38;2;232;120;192m(&)
[38;2;216;216;216m                 '---'     [38;2;255;121;198m'(&)[38;2;232;120;192m'
[38;2;217;96;168m
[38;2;232;120;192m   *       .    *        .    *       .    *        .
[38;2;217;96;168m       .  *  .    *   .  *  .    *   .  *  .    *   .  *  .[0m

[38;2;216;216;216m   this system welcomes authorized visitors
[38;2;112;201;221m   connections are logged with care[0m

EOF
