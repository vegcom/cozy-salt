#!/bin/bash
# Generate /etc/motd (post-login banner)
# Called by salt state or cron - outputs to stdout
# pastel goth aesthetic - twilite theme

# System info
HOSTNAME=$(uname -n)
KERNEL=$(uname -r)
ARCH=$(uname -m)
UPTIME=$(uptime -p 2>/dev/null | sed 's/up //' || echo "unknown")
LOAD=$(cut -d' ' -f1-3 /proc/loadavg 2>/dev/null || echo "? ? ?")
MEM_TOTAL=$(free -h 2>/dev/null | awk '/^Mem:/{print $2}' || echo "?")
MEM_USED=$(free -h 2>/dev/null | awk '/^Mem:/{print $3}' || echo "?")
DISK_ROOT=$(df -h / 2>/dev/null | awk 'NR==2{print $3"/"$2" ("$5")"}' || echo "?")

# Twilite palette - true color ANSI
PURPLE=$'\e[38;2;217;96;168m'       # #d960a8 - main accent
BRIGHT_PURPLE=$'\e[38;2;232;120;192m'  # #e878c0 - highlights
CYAN=$'\e[38;2;112;201;221m'        # #70c9dd - info
HOTPINK=$'\e[38;2;255;121;198m'     # #ff79c6 - special
FG=$'\e[38;2;216;216;216m'          # #d8d8d8 - text
X=$'\e[0m'                          # reset

cat << EOF

${PURPLE}        .  *  .       *    .        *       .    *
${BRIGHT_PURPLE}    *        .    ${HOTPINK}~ welcome home ~${BRIGHT_PURPLE}    .        *
${PURPLE}      .    *    .        *      .       *   .

${FG}    .--.      ${CYAN}${HOSTNAME}${FG}
${FG}   /    \\     ${PURPLE}kernel${FG}  ${CYAN}${KERNEL}${FG} (${ARCH})
${FG}   \\    /     ${PURPLE}uptime${FG}  ${CYAN}${UPTIME}${FG}
${FG}    '--'      ${PURPLE}load${FG}    ${CYAN}${LOAD}${FG}
${FG}   _|__|_     ${PURPLE}memory${FG}  ${CYAN}${MEM_USED}${FG} / ${MEM_TOTAL}
${FG}  |      |    ${PURPLE}disk /${FG}  ${CYAN}${DISK_ROOT}${FG}
${FG}  |______|

${BRIGHT_PURPLE}   .  *  ${HOTPINK}cozy-salt managed${BRIGHT_PURPLE}  *  .${X}

${FG}         ${PURPLE}*${FG} stay cozy ${PURPLE}*${FG} be gentle ${PURPLE}*${X}

${BRIGHT_PURPLE}  "the system is down. the system is down."${X}
${FG}                              - strong bad, probably${X}

EOF
