# GPU Detection and Grain Setting

Detect GPU type and set Salt grains for later use by other states.

## Location

- **State**: `srv/salt/common/gpu.sls`
- **Include**: `common.init`

## Detection

Checks system hardware and sets grain:

| GPU Type | Grain Value | Detection |
|----------|------------|-----------|
| NVIDIA | nvidia | lspci: NVIDIA Corporation |
| AMD | amd | lspci: AMD/ATI |
| Intel | intel | lspci: Intel Corporation (integrated) |
| None | none | No GPU detected |

## Usage in States

Other states reference the grain:

```sls
{% if grains['gpu_type'] == 'nvidia' %}
  # NVIDIA-specific config
{% endif %}
```

## Effect

Sets grain: `gpu_type`

Available via:
```bash
salt grains.item gpu_type
```

## Notes

- Linux only (GPU detection via lspci)
- Requires lspci (installed via monitoring packages)
- Detected once per provisioning (static until next run)
- Used by display managers, Docker runtime, etc. for GPU acceleration
