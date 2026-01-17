# GPU Detection - Sets grain for platform-specific GPU driver installation
# Detects: nvidia, amd (Steam Deck/RDNA), other (intel/generic/none)
# Primarily used by Linux, but detects on all platforms for consistency

detect_gpu_type:
  cmd.run:
    - name: |
        if lspci 2>/dev/null | grep -qi "NVIDIA"; then
          echo "nvidia"
        elif lspci 2>/dev/null | grep -qi "AMD\|Radeon\|AMDGPU"; then
          echo "amd"
        else
          echo "other"
        fi
    - stateful: False
    - onlyif: 'test -x /usr/bin/lspci'

set_gpu_grain:
  grains.present:
    - name: linux_gpu
    - value: other
    - require:
      - cmd: detect_gpu_type
