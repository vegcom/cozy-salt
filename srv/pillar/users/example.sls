#!jinja|yaml
# Example User Pillar Override
# Define per-user configurations that apply across all systems
# These override common/users.sls values for specific users

# Example: Override user github config (email and name in .gitconfig.local)
# This applies to all systems unless overridden at host/ or class/ level
users:
  vegcom:
    github:
      email: custom-vegcom@example.com
      name: Custom Vegcom Name
      # Tokens merge with global tokens from common/users.sls
      tokens:
        - ghp_vegcom_custom_token_123

  eve:
    github:
      email: eve-custom@example.com
      name: Eve Custom
      tokens:
        - ghp_eve_custom_token_456

  admin:
    github:
      email: admin-custom@example.com
      name: Admin Custom
      tokens:
        - ghp_admin_custom_token_789
