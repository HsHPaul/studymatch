"""
Seed-Script für Demo-Daten.
Legt 10 Fächer, 5 Räume und 3 Demo-User mit Profil/Fächern/Zeitfenstern an.
Idempotent: mehrfaches Ausführen macht nichts kaputt.

Aufruf: python scripts/seed.py  (aus dem backend/-Verzeichnis)
"""
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from datetime import time
from app.core.database import SessionLocal
from app.core.security import hash_password
from app.models.user import User
from app.models.subject import Subject, UserSubject
from app.models.availability import Availability
from app.models.room import Room
from app.models.enums import Lernstil, Wochentag

SUBJECTS = [
    ("Analysis I", "ANA1"),
    ("Analysis II", "ANA2"),
    ("Lineare Algebra", "LA"),
    ("Algorithmen & Datenstrukturen", "ADS"),
    ("Softwaretechnik", "SWT"),
    ("Datenbanken", "DB"),
    ("Betriebssysteme", "BS"),
    ("Rechnernetze", "RN"),
    ("Theoretische Informatik", "THI"),
    ("Statistik", "STAT"),
]

ROOMS = [
    ("Hauptgebäude", "H001", 6),
    ("Hauptgebäude", "H002", 4),
    ("Bibliothek", "B101", 8),
    ("Bibliothek", "B102", 4),
    ("Informatikgebäude", "I204", 6),
]

USERS = [
    {
        "alias": "alice",
        "email": "alice@demo.local",
        "password": "demo1234",
        "studiengang": "Informatik",
        "lernstil": Lernstil.still,
        "bio": "Lerne gerne strukturiert und ruhig.",
        "subjects": ["Analysis I", "Lineare Algebra", "Algorithmen & Datenstrukturen"],
        "availabilities": [
            (Wochentag.montag, time(10, 0), time(12, 0)),
            (Wochentag.mittwoch, time(14, 0), time(16, 0)),
        ],
    },
    {
        "alias": "bob",
        "email": "bob@demo.local",
        "password": "demo1234",
        "studiengang": "Informatik",
        "lernstil": Lernstil.diskutierend,
        "bio": "Erkläre Konzepte am liebsten laut.",
        "subjects": ["Analysis I", "Datenbanken", "Algorithmen & Datenstrukturen"],
        "availabilities": [
            (Wochentag.montag, time(10, 0), time(13, 0)),
            (Wochentag.donnerstag, time(9, 0), time(11, 0)),
        ],
    },
    {
        "alias": "carol",
        "email": "carol@demo.local",
        "password": "demo1234",
        "studiengang": "Mathematik",
        "lernstil": Lernstil.gemischt,
        "bio": "Bin flexibel – mal ruhig, mal diskutierend.",
        "subjects": ["Analysis I", "Analysis II", "Statistik", "Lineare Algebra"],
        "availabilities": [
            (Wochentag.mittwoch, time(14, 0), time(17, 0)),
            (Wochentag.freitag, time(10, 0), time(12, 0)),
        ],
    },
]


def seed():
    db = SessionLocal()
    try:
        # Fächer
        subject_map: dict[str, Subject] = {}
        for name, kuerzel in SUBJECTS:
            existing = db.query(Subject).filter(Subject.name == name).first()
            if not existing:
                s = Subject(name=name, kuerzel=kuerzel)
                db.add(s)
                db.flush()
                subject_map[name] = s
            else:
                subject_map[name] = existing

        # Räume
        for gebaeude, raumname, kapazitaet in ROOMS:
            exists = db.query(Room).filter(Room.raumname == raumname).first()
            if not exists:
                db.add(Room(gebaeude=gebaeude, raumname=raumname, kapazitaet=kapazitaet))

        # Nutzer
        for u in USERS:
            existing_user = db.query(User).filter(User.email == u["email"]).first()
            if existing_user:
                continue

            user = User(
                alias=u["alias"],
                email=u["email"],
                hashed_password=hash_password(u["password"]),
                studiengang=u["studiengang"],
                lernstil=u["lernstil"],
                bio=u["bio"],
            )
            db.add(user)
            db.flush()

            for subject_name in u["subjects"]:
                subj = subject_map[subject_name]
                db.add(UserSubject(user_id=user.id, subject_id=subj.id))

            for wochentag, start, end in u["availabilities"]:
                db.add(Availability(
                    user_id=user.id,
                    wochentag=wochentag,
                    start_time=start,
                    end_time=end,
                ))

        db.commit()
        print("Seed abgeschlossen.")
    except Exception as e:
        db.rollback()
        print(f"Fehler beim Seed: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed()
