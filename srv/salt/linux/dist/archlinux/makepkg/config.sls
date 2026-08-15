# ============================================================================
# MAKEPKG CONFIGURATION - DISTCC_HOSTS
# ----------------------------------------------------------------------------

makepkg_cozy_conf:
  file.managed:
    - name: /etc/makepkg.conf.d/cozy.conf
    - mode: "0644"
    - user: root
    - group: root
    - contents: |
        #!/hint/bash
        # Managed by cozy-salt - DO NOT EDIT MANUALLY
        # Legacy - ref: /etc/makepkg.conf.d/cozy-build.conf

makepkg_build_conf:
  file.managed:
    - name: /etc/makepkg.conf.d/cozy-build.conf
    - mode: "0644"
    - user: root
    - group: root
    - contents: |
        #!/hint/bash
        # Managed by cozy-salt - DO NOT EDIT MANUALLY
        BUILDENV=(color ccache check)
