# Common mine_functions, merged (recurse) with any host-specific mine_functions
# in srv/pillar/host/*.sls — see pillar_source_merging_strategy in master.d.
mine_functions:
  id:
    mine_function: grains.get
    key: id
  num_cpus:
    mine_function: grains.get
    key: num_cpus
