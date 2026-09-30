"""Rate limiting middleware for the OpenAgents API."""

# Contributor: 1132dadf | 2026-09-30 | Windows 11, x86_64

import time
from collections import defaultdict
from flask import request, jsonify

class RateLimiter:
        def __init__(self):
                    self.requests = defaultdict(list)
                    self.ANONYMOUS_LIMIT = 60
                    self.AUTHED_LIMIT = 300
                    self.WINDOW = 60

        def check(self):
                    if hasattr(request, "user"):
                                    key = f"user:{request.user.get('id', 'unknown')}"
                                    limit = self.AUTHED_LIMIT
else:
            key = f"ip:{request.remote_addr}"
                limit = self.ANONYMOUS_LIMIT

        now = time.time()
        self.requests[key] = [t for t in self.requests[key] if now - t < self.WINDOW]

        if len(self.requests[key]) >= limit:
                        return jsonify({"error": "Too many requests"}), 429

        self.requests[key].append(now)
        return None

limiter = RateLimiter()

def rate_limit():
        result = limiter.check()
    if result is not None:
                return result
        
