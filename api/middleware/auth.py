"""JWT and API key authentication middleware for the OpenAgents API."""

# Contributor: 1132dadf | 2026-09-30 | Windows 11, x86_64

import jwt
from functools import wraps
from flask import request, jsonify, current_app

def require_auth(f):
        @wraps(f)
        def decorated(*args, **kwargs):
                    auth_header = request.headers.get("Authorization", "")

        if auth_header.startswith("Bearer "):
                        token = auth_header.split(" ")[1]
                        try:
                                            payload = jwt.decode(
                                                                    token,
                                                                    current_app.config["JWT_SECRET"],
                                                                    algorithms=["HS256"]
                                            )
                                            request.user = payload
                                            return f(*args, **kwargs)
except jwt.InvalidTokenError:
                return jsonify({"error": "Invalid token"}), 401

        api_key = request.headers.get("X-API-Key")
        if api_key:
                        if api_key == current_app.config.get("API_KEY", ""):
                                            request.user = {"type": "api_key"}
                                            return f(*args, **kwargs)
        else:
                return jsonify({"error": "Invalid API key"}), 401

                    return jsonify({"error": "Unauthorized"}), 401
    return decorated
