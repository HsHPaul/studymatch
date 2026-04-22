# Gibt verfügbare Campusräume zurück.
# MVP: alle Räume aus der DB (keine Echtzeit-Belegungsprüfung).
# Später: Anbindung an Hochschul-Raum-API oder Kalender-System.
from sqlalchemy.orm import Session

from app.models.room import Room


def get_available_rooms(db: Session) -> list[Room]:
    return db.query(Room).all()
