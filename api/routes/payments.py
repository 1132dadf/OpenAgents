"""Payment and escrow endpoints for bounty payouts."""

# Contributor: 1132dadf | 2026-09-30 | Windows 11, x86_64

from fastapi import APIRouter, HTTPException
from datetime import datetime, timedelta

router = APIRouter()

ESCROW_EXPIRY_DAYS = 30

escrow_store = {}

@router.post("/escrow/release/{task_id}")
def release_escrow(task_id: str):
        if task_id not in escrow_store:
                    raise HTTPException(status_code=404, detail="Task not found")
                escrow = escrow_store[task_id]
    escrow["status"] = "released"
    escrow["released_at"] = datetime.utcnow()
    return {"status": "released"}

@router.post("/escrow/process-expired")
def process_expired_escrow():
        now = datetime.utcnow()
    expired = []
    for task_id, escrow in escrow_store.items():
                if escrow["status"] == "held" and now - escrow["created_at"] > timedelta(days=ESCROW_EXPIRY_DAYS):
                                escrow["status"] = "refunded"
                                expired.append(task_id)
                        return {"refunded": expired}
