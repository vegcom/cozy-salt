#!/bin/bash
#-----------------------------------------------
# Only run when sourced
(return 0 2>/dev/null) || exit 0

# Gate, only run for interactive root ssh sessions
if [[ $- != *i* ]] || [[ $EUID -ne 0 ]] || [[ -z "$SSH_CONNECTION" ]]; then
    return
fi


#-----------------------------------------------
# host cpu
cpu_load() {
    read -r cpu user nice system idle iowait irq softirq steal _ < /proc/stat
    busy=$((user + nice + system + irq + softirq + steal))
    total=$((busy + idle + iowait))
    echo "$busy $total"
}

read -r b1 t1 < <(cpu_load)
sleep 0.3
read -r b2 t2 < <(cpu_load)

cpu_pct=$(awk -v b1="$b1" -v t1="$t1" -v b2="$b2" -v t2="$t2" \
    'BEGIN {printf "%.1f", 100*(b2-b1)/(t2-t1)}')


#-----------------------------------------------
# host mem
mem_used() {
    awk '
        /MemTotal/ {t=$2}
        /MemAvailable/ {a=$2}
        END {
            u=(t-a)/1024/1024
            t=t/1024/1024
            printf "%.1fGi / %.0fGi", u, t
        }
    ' /proc/meminfo
}

host_mem=$(mem_used)


#-----------------------------------------------
# load container
read load1 load5 load15 _ < /proc/loadavg


#-----------------------------------------------
# enum ssh
ssh_sessions="$(
  who -s | awk '/sshd/ {
      gsub(/[()]/, "", $6)
      print "  " $4 "T" $5 " " $1 "[" $2 "] " $6
  }' | sort -hk1 | uniq
)"


#-----------------------------------------------
# detect docker
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    have_docker=1
else
    have_docker=0
fi

#-----------------------------------------------
# cgroup v2
docker_cpu() {
    cg="$1"
    u1=$(awk '/usage_usec/ {print $2}' "$cg/cpu.stat" 2>/dev/null)
    sleep 0.3
    u2=$(awk '/usage_usec/ {print $2}' "$cg/cpu.stat" 2>/dev/null)
    [[ -z "$u1" || -z "$u2" ]] && { printf "0.0"; return; }
    awk -v u1="$u1" -v u2="$u2" 'BEGIN {printf "%.1f", 100*(u2-u1)/300000}'
}

docker_mem() {
    cg="$1"
    cur=$(cat "$cg/memory.current" 2>/dev/null)
    max=$(cat "$cg/memory.max" 2>/dev/null)
    [[ -z "$cur" ]] && { printf "0Mi / 0Mi"; return; }

    cur_mi=$(awk -v c="$cur" 'BEGIN {printf "%.1f", c/1024/1024}')
    if [[ "$max" == "max" || -z "$max" ]]; then
        printf "%sMi / ∞" "$cur_mi"
    else
        max_mi=$(awk -v m="$max" 'BEGIN {printf "%.0f", m/1024/1024}')
        printf "%sMi / %sMi" "$cur_mi" "$max_mi"
    fi
}

#-----------------------------------------------
# Detect SSH
if [[ -n "$SSH_CONNECTION" ]]; then
    host_label="$(hostname) (ssh)"
else
    host_label="$(hostname)"
fi


#-----------------------------------------------
# Render host
printf "[ host: %s ]\n" "$host_label"
printf "  cpu   %s%%\n" "$cpu_pct"
printf "  mem   %s\n" "$host_mem"
printf "  load  %s %s %s\n" "$load1" "$load5" "$load15"
printf "\n"


#-----------------------------------------------
# render ssh
printf "[ ssh ]\n"
if [[ -z "$ssh_sessions" ]]; then
    printf "  none\n\n"
else
    printf "%s\n\n" "$ssh_sessions"
fi


#-----------------------------------------------
# container by name
if [[ $have_docker -eq 1 ]]; then
    printf "[ containers ]\n"

    containers=$(docker ps --format '{{.ID}} {{.Names}}')

    if [[ -z "$containers" ]]; then
        printf "  none\n\n"
    else
        i=0
        while read -r cid name; do
            [[ -z "$cid" ]] && continue

            # cgroup v2 path (modern Docker)
            cg="/sys/fs/cgroup/$cid"
            [[ ! -d "$cg" ]] && continue

            cpu=$(docker_cpu "$cg")
            mem=$(docker_mem "$cg")

            case $((i % 3)) in
                0) bg="\e[48;2;60;60;80m"  ;;
                1) bg="\e[48;2;70;60;90m"  ;;
                2) bg="\e[48;2;80;60;100m" ;;
            esac

            printf "  %b %-18s cpu %-5s mem %s %b\n" \
                "$bg" "$name" "$cpu%" "$mem" "\e[0m"

            i=$((i+1))
        done <<< "$containers"

        printf "\n"
    fi
fi
