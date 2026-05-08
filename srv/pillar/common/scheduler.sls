#!jinja|yaml
# Salt Scheduler Pillar Configuration

schedule:

  mongo_returner_sync:
    function: state.sls
    args:
      - common.mongo_returner
    minutes: 60
    enabled: true

  salt_version_sync:
    function: state.sls
    args:
      - common.salt
    hours: 48
    enabled: true
