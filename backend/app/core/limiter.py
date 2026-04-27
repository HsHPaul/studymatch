# Gemeinsame Rate-Limiter-Instanz. Hier zentralisiert um zirkuläre Imports zu vermeiden.
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
