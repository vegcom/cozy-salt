{#-
  NOTES: I may have messed up
    - `cat /usr/share/yay/meta/.luarc.json | tee ~/.config/yay/.luarc.json` to eval
    - diff --color=auto --side-by-side <(yay -P --defaultconfig|jq 'to_entries | sort_by(.key) | from_entries') <(yay -P --currentconfig|jq 'to_entries | sort_by(.key) | from_entries')
      - eval changes as they are made
    - config should be via [init.lua](https://jguer.github.io/yay/man.html) not config.json. whoops💀
#}

include:
  - linux.dist.archlinux.yay.bootstrap
  - linux.dist.archlinux.yay.config
  - linux.dist.archlinux.yay.hooks
