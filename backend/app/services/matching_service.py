# Kernlogik des Matchings: findet passende Lernpartner für einen Nutzer.
# Pflicht: mind. 1 gemeinsames Fach + mind. 1 überlappende Verfügbarkeit.
# Score: Fach 40% | Lernstil 25% | Zeitüberlappung 20% | Studiengang 10%
from sqlalchemy.orm import Session

from app.models.user import User
from app.models.availability import Availability
from app.schemas.matching import MatchResponse, AvailabilityOverlap


def find_matches(current_user: User, db: Session) -> list[MatchResponse]:
    candidates = db.query(User).filter(User.id != current_user.id).all()
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

        results.append(
            MatchResponse(
                user_id=candidate.id,
                alias=candidate.alias,
                studiengang=candidate.studiengang,
                lernstil=candidate.lernstil,
                gemeinsame_faecher=gemeinsame_names,
                ueberschneidungen=overlaps,
                score=score,
            )
        )

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
            overlap_start = max(a.start_time, b.start_time)
            overlap_end = min(a.end_time, b.end_time)
            if overlap_start < overlap_end:
                overlaps.append(
                    AvailabilityOverlap(
                        wochentag=a.wochentag,
                        start_time=str(overlap_start),
                        end_time=str(overlap_end),
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
    score += fach_score * 0.40

    if user_a.lernstil and user_b.lernstil and user_a.lernstil == user_b.lernstil:
        score += 0.25

    overlap_score = min(len(overlaps) / 3, 1.0)
    score += overlap_score * 0.20

    if user_a.studiengang and user_b.studiengang and user_a.studiengang == user_b.studiengang:
        score += 0.10

    return round(score, 3)
