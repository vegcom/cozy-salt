# Salt Scheduler Module

Define periodic jobs for minions via the Salt scheduler.

## Location

- **Pillar**: `srv/pillar/common/scheduler.sls`
- **State**: `srv/salt/common/scheduler.sls`
- **Include**: Applied via `common.init`

## Configuration

Define scheduled jobs in pillar data:

```yaml
schedule:
  job_name:
    function: state.sls
    seconds: 3600
    args:
      - state_name
```

## Time Specifications

| Option | Example | Note |
|--------|---------|------|
| `seconds` | `3600` | Interval in seconds |
| `minutes` | `60` | Interval in minutes |
| `hours` | `24` | Interval in hours |
| `days` | `7` | Interval in days |
| `cron` | `*/15 * * * *` | Cron expression (requires python-croniter) |
| `when` | `5:00pm` | Specific time |
| `start` / `end` | `8:00am` / `5:00pm` | Time range for execution |

## Job Configuration Options

| Option | Type | Description |
|--------|------|-------------|
| `function` | string | **Required**. Module function to execute (e.g., `state.sls`, `state.highstate`) |
| `args` | list | Positional arguments passed to function |
| `kwargs` | dict | Keyword arguments passed to function |
| `splay` | dict | Randomize job start time (object with `start` and `end` keys) |
| `enabled` | bool | Enable/disable job (default: true) |
| `return_job` | bool | Return job results to master (default: false) |

## Examples

### Run state every 24 hours

```yaml
schedule:
  daily_update:
    function: state.highstate
    hours: 24
```

### Run every 15 minutes (cron-style)

```yaml
schedule:
  frequent_check:
    function: state.sls
    cron: '*/15 * * * *'
    args:
      - my.state
```

### Run during business hours with random start

```yaml
schedule:
  business_hours_update:
    function: state.sls
    seconds: 300
    args: [my.state]
    splay:
      start: 10
      end: 15
    start: 8:00am
    end: 5:00pm
```

### Run with job results returned to master

```yaml
schedule:
  monitoring_job:
    function: cmd.run
    args:
      - 'systemctl status docker'
    cron: '*/5 * * * *'
    return_job: true
```

## Implementation Details

The scheduler state (`srv/salt/common/scheduler.sls`) iterates over pillar schedule data and applies `schedule.present` states for each job.

- No schedules defined = no-op (idempotent)
- Supports all Salt scheduler options
- Changes to pillar require `saltutil.refresh_pillar` to take effect
- Schedules are persisted to minion filesystem by default

## Management Commands

On minions or master:

```bash
salt '*' schedule.list              # View all scheduled jobs
salt '*' schedule.add job_name ...  # Add job dynamically
salt '*' schedule.modify job_name ...  # Update job
salt '*' schedule.delete job_name   # Remove job
salt '*' schedule.enable            # Enable scheduler
salt '*' schedule.disable           # Disable scheduler
```

## See Also

- [Salt Scheduler Documentation](https://docs.saltproject.io/salt/user-guide/en/latest/topics/scheduler.html)
- [Schedule State Module](https://docs.saltproject.io/en/latest/ref/states/all/salt.states.schedule.html)
