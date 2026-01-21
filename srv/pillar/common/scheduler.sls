#!jinja|yaml
# Salt Scheduler Pillar Configuration
# Define periodic jobs for minions via the Salt scheduler
#
# Usage:
#   Define schedule jobs in your pillar data:
#
#   schedule:
#     job_name:
#       function: state.sls
#       seconds: 3600
#       args:
#         - state_name
#
#   Supported time specifications:
#     - seconds/minutes/hours/days: interval-based
#     - cron: cron expression (requires python-croniter)
#     - when: specific time (5:00pm)
#     - start/end: time range
#
# Examples:
#   Run state.highstate every 24 hours:
#     schedule:
#       daily_update:
#         function: state.highstate
#         hours: 24
#
#   Run every 15 minutes:
#     schedule:
#       frequent_check:
#         function: state.sls
#         cron: '*/15 * * * *'
#         args:
#           - my.state
#
#   Run with splay (randomized start):
#     schedule:
#       update_with_splay:
#         function: state.sls
#         seconds: 300
#         args: [my.state]
#         splay:
#           start: 10
#           end: 15

schedule: {}
