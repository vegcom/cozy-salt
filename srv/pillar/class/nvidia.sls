{#- NVIDIA container runtime config for docker + k3s #}
{%- if grains['kernel'] == "Linux" and grains['gpu_vendor'] == "nvidia" %}
docker:
  default-runtime: nvidia
  experimental: true
  features:
    containerd-snapshotter: true
  runtimes:
    nvidia:
      path: nvidia-container-runtime
      args: []
k3s:
  kwargs_opt: "--default-runtime=nvidia"
{%- endif %}
