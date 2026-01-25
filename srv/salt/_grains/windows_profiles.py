"""
Custom grain for Windows user profile detection.
Returns list of users who have actually logged in (have profile directories).
"""

import logging
import os

log = logging.getLogger(__name__)


def _get_logged_in_users():
    """
    Detect Windows users who have logged in by checking profile directories.
    Filters out system accounts and temp/corrupted profiles.
    """
    users = []
    temp_profiles = []

    if os.name != 'nt':
        return {'logged_in_users': [], 'temp_profiles': []}

    users_dir = r'C:\Users'
    
    # System/built-in accounts to skip
    skip_accounts = {
        'default', 'default user', 'public', 'all users',
        'defaultapppool', 'administrator'
    }

    try:
        for entry in os.listdir(users_dir):
            entry_lower = entry.lower()
            entry_path = os.path.join(users_dir, entry)

            # Skip non-directories
            if not os.path.isdir(entry_path):
                continue

            # Skip system accounts
            if entry_lower in skip_accounts:
                continue

            # Detect temp/corrupted profiles (user.HOSTNAME pattern)
            if '.' in entry and not entry.startswith('.'):
                parts = entry.split('.')
                if len(parts) == 2 and parts[0].lower() not in skip_accounts:
                    temp_profiles.append(entry)
                    continue

            # Check for NTUSER.DAT (indicates real login)
            ntuser_path = os.path.join(entry_path, 'NTUSER.DAT')
            if os.path.exists(ntuser_path):
                users.append(entry)

    except Exception as e:
        log.error(f'Error detecting Windows profiles: {e}')

    return {
        'logged_in_users': sorted(users),
        'temp_profiles': sorted(temp_profiles),
    }


def windows_profiles():
    """
    Grain function - returns profile detection data.
    
    Usage in states:
        {% set logged_in = salt['grains.get']('logged_in_users', []) %}
        {% set temp_profiles = salt['grains.get']('temp_profiles', []) %}
    """
    grains = {}
    
    profile_data = _get_logged_in_users()
    grains['logged_in_users'] = profile_data['logged_in_users']
    grains['temp_profiles'] = profile_data['temp_profiles']
    grains['has_temp_profiles'] = len(profile_data['temp_profiles']) > 0
    
    return grains
