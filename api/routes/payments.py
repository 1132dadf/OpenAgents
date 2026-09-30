

def check_expired_escrows():
            # Fix: auto-refund escrow that has been held for more than 7 days without release
            import time
            from models.database import db, Escrow

    expired = Escrow.query.filter(
                    Escrow.status == "held",
                    Escrow.created_at < int(time.time()) - 7*24*60*60
    ).all()

    for escrow in expired:
                    # Auto refund to payer if no activity in 7 days
                    escrow.status = "refunded"
                    # Send refund notification
                    print(f"Auto refunded escrow {escrow.id} to payer {escrow.payer_id}")

    db.session.commit()
