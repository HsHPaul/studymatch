from datetime import datetime, timezone, timedelta

from apscheduler.schedulers.background import BackgroundScheduler

from app.core.database import SessionLocal
from app.models.user import User

_TWO_YEARS = timedelta(days=365 * 2)


def delete_inactive_users() -> None:
    cutoff = datetime.now(timezone.utc) - _TWO_YEARS
    db = SessionLocal()
    try:
        count = (
            db.query(User)
            .filter(User.last_login_at.isnot(None), User.last_login_at < cutoff)
            .delete(synchronize_session=False)
        )
        db.commit()
        if count:
            print(f"[cleanup] {count} inaktive(r) Account(s) gelöscht (kein Login seit {cutoff.date()}).")
    finally:
        db.close()


scheduler = BackgroundScheduler(timezone="UTC")
scheduler.add_job(delete_inactive_users, trigger="interval", days=1, id="inactive_user_cleanup")
