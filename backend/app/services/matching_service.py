# Kern-Matching-Logik: findet und bewertet passende Lernpartner.
# Pflicht: mind. 1 gemeinsames Fach + mind. 1 überlappende Verfügbarkeit.
import math
from datetime import time
from sqlalchemy.orm import Session, selectinload

from app.models.user import User
from app.models.match import Match
from app.models.subject import UserSubject
from app.models.availability import Availability
from app.schemas.matching import MatchResponse, AvailabilityOverlap

# Scoring-Gewichte (müssen zusammen 1.0 ergeben)
WEIGHT_SUBJECT = 0.45      # 0.05 aus Lernziel-Reserve hier bis Lernziel-Feature kommt
WEIGHT_LERNSTIL = 0.25
WEIGHT_TIME = 0.20
WEIGHT_STUDIENGANG = 0.10
MAX_OVERLAP_COUNT = 3
assert math.isclose(WEIGHT_SUBJECT + WEIGHT_LERNSTIL + WEIGHT_TIME + WEIGHT_STUDIENGANG, 1.0)


def find_matches(current_user: User, db: Session) -> list[MatchResponse]:
    candidates = (
        db.query(User)
        .filter(User.id != current_user.id)
        .options(
            selectinload(User.subjects).selectinload(UserSubject.subject),
            selectinload(User.availabilities),
        )
        .all()
    )

    current_subject_ids = {us.subject_id for us in current_user.subjects}
    results = []

    for candidate in candidates:
        candidate_subject_ids = {us.subject_id for us in candidate.subjects}
        gemeinsame = current_subject_ids & candidate_subject_ids

        if not gemeinsame:
            continue

        overlaps = _find_time_overlaps(current_user.availabilities, candidate.availabilities)
        if not overlaps:
            continue

        score = _calculate_score(current_user, candidate, gemeinsame, overlaps)
        gemeinsame_names = [
            us.subject.name for us in candidate.subjects if us.subject_id in gemeinsame
        ]

        # Find or create the Match record so the frontend has a valid match_id
        db_match = db.query(Match).filter(
            ((Match.user_a_id == current_user.id) & (Match.user_b_id == candidate.id)) |
            ((Match.user_b_id == current_user.id) & (Match.user_a_id == candidate.id))
        ).first()
        if not db_match:
            db_match = Match(
                user_a_id=current_user.id,
                user_b_id=candidate.id,
                score=score,
            )
            db.add(db_match)
            db.flush()

        results.append(
            MatchResponse(
                match_id=db_match.id,
                user_id=candidate.id,
                alias=candidate.alias,
                studiengang=candidate.studiengang,
                lernstil=candidate.lernstil,
                gemeinsame_faecher=gemeinsame_names,
                ueberschneidungen=overlaps,
                score=score,
            )
        )

    db.commit()
    results.sort(key=lambda x: x.score, reverse=True)
    return results[:10]


def _find_time_overlaps(
    avail_a: list[Availability],
    avail_b: list[Availability],
) -> list[AvailabilityOverlap]:
    overlaps = []
    for a in avail_a:
        for b in avail_b:
            if a.wochentag != b.wochentag:
                continue
            overlap_start: time = max(a.start_time, b.start_time)
            overlap_end: time = min(a.end_time, b.end_time)
            if overlap_start < overlap_end:
                overlaps.append(
                    AvailabilityOverlap(
                        wochentag=a.wochentag,
                        start_time=overlap_start,
                        end_time=overlap_end,
                    )
                )
    return overlaps


def _calculate_score(
    user_a: User,
    user_b: User,
    gemeinsame_faecher: set,
    overlaps: list[AvailabilityOverlap],
) -> float:
    score = 0.0

    fach_score = min(len(gemeinsame_faecher) / max(len(user_a.subjects), 1), 1.0)
    score += fach_score * WEIGHT_SUBJECT

    if user_a.lernstil and user_b.lernstil and user_a.lernstil == user_b.lernstil:
        score += WEIGHT_LERNSTIL

    score += min(len(overlaps) / MAX_OVERLAP_COUNT, 1.0) * WEIGHT_TIME

    if user_a.studiengang and user_b.studiengang and user_a.studiengang == user_b.studiengang:
        score += WEIGHT_STUDIENGANG

    return round(score, 3)
