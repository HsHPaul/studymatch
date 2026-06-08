# Profilverwaltung: eigenes Profil lesen/bearbeiten sowie
# Fächer und Zeitfenster hinzufügen/entfernen.
# Ohne Fächer und Zeitfenster kann das Matching keine Ergebnisse liefern.
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.core.database import get_db
from app.core.security import hash_password, verify_password
from app.models.match import Match
from app.models.user import User
from app.models.subject import Subject, UserSubject
from app.models.availability import Availability
from app.schemas.profile import (
    PasswordChange,
    ProfileUpdate,
    ProfileResponse,
    SubjectAdd,
    SubjectResponse,
    AvailabilityCreate,
    AvailabilityResponse,
)

router = APIRouter(prefix="/profiles", tags=["profiles"])


@router.get("/subjects", response_model=list[SubjectResponse])
def get_all_subjects(db: Session = Depends(get_db)):
    return db.query(Subject).order_by(Subject.name).all()


@router.get("/me", response_model=ProfileResponse)
def get_my_profile(current_user: User = Depends(get_current_user)):
    return current_user


@router.patch("/me", response_model=ProfileResponse)
def update_my_profile(
    payload: ProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    for field, value in payload.model_dump(exclude_none=True).items():
        setattr(current_user, field, value)
    db.commit()
    db.refresh(current_user)
    return current_user


@router.patch("/me/password", status_code=status.HTTP_204_NO_CONTENT)
def change_password(
    payload: PasswordChange,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if not verify_password(payload.current_password, current_user.hashed_password):
        raise HTTPException(status_code=400, detail="Aktuelles Passwort ist falsch")
    current_user.hashed_password = hash_password(payload.new_password)
    db.commit()


@router.get("/me/subjects", response_model=list[SubjectResponse])
def get_my_subjects(current_user: User = Depends(get_current_user)):
    return [us.subject for us in current_user.subjects]


@router.post("/me/subjects", response_model=SubjectResponse, status_code=status.HTTP_201_CREATED)
def add_subject(
    payload: SubjectAdd,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    subject = db.query(Subject).filter(Subject.id == payload.subject_id).first()
    if not subject:
        raise HTTPException(status_code=404, detail="Fach nicht gefunden")
    already_added = any(us.subject_id == payload.subject_id for us in current_user.subjects)
    if already_added:
        raise HTTPException(status_code=400, detail="Fach bereits im Profil")
    db.add(UserSubject(user_id=current_user.id, subject_id=payload.subject_id))
    db.commit()
    return subject


@router.delete("/me/subjects/{subject_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_subject(
    subject_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    entry = db.query(UserSubject).filter(
        UserSubject.user_id == current_user.id,
        UserSubject.subject_id == subject_id,
    ).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Fach nicht im Profil")
    db.delete(entry)
    db.commit()


@router.get("/me/availabilities", response_model=list[AvailabilityResponse])
def get_my_availabilities(current_user: User = Depends(get_current_user)):
    return current_user.availabilities


@router.post("/me/availabilities", response_model=AvailabilityResponse, status_code=status.HTTP_201_CREATED)
def add_availability(
    payload: AvailabilityCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    avail = Availability(user_id=current_user.id, **payload.model_dump())
    db.add(avail)
    db.commit()
    db.refresh(avail)
    return avail


@router.delete("/me/availabilities/{availability_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_availability(
    availability_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    avail = db.query(Availability).filter(
        Availability.id == availability_id,
        Availability.user_id == current_user.id,
    ).first()
    if not avail:
        raise HTTPException(status_code=404, detail="Zeitfenster nicht gefunden")
    db.delete(avail)
    db.commit()


@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
def delete_my_account(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    # Matches (inkl. Nachrichten und Sessions via Cascade) zuerst löschen,
    # da kein ON DELETE CASCADE in der DB für matches.user_a/b_id definiert ist.
    db.query(Match).filter(
        (Match.user_a_id == current_user.id) | (Match.user_b_id == current_user.id)
    ).delete(synchronize_session=False)
    db.delete(current_user)
    db.commit()
