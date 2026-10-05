import sys
from slowapi import Limiter
from slowapi.util import get_remote_address

is_testing = "pytest" in sys.modules or (len(sys.argv) > 0 and "pytest" in sys.argv[0])

limiter = Limiter(
    key_func=get_remote_address,
    default_limits=["100/minute"],
    enabled=not is_testing
)
