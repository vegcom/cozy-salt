"""
user_homes grain — deprecated, use get_user_home() macro from _macros/dotfiles.sls
instead. Kept as a no-op to avoid breaking existing grain references during
transition.
"""

import logging

log = logging.getLogger(__name__)


def user_homes():
    return {"user_homes": {}}
