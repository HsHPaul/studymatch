# Zentrale Enum-Definitionen für alle Domänenwerte.
# Einmal hier definieren, in Models UND Schemas importieren –
# so können Model und Schema nie still auseinanderlaufen.
import enum


class Lernstil(str, enum.Enum):
    still = "still"
    gemischt = "gemischt"
    diskutierend = "diskutierend"


class Wochentag(str, enum.Enum):
    montag = "montag"
    dienstag = "dienstag"
    mittwoch = "mittwoch"
    donnerstag = "donnerstag"
    freitag = "freitag"
    samstag = "samstag"


class MatchStatus(str, enum.Enum):
    vorgeschlagen = "vorgeschlagen"
    akzeptiert = "akzeptiert"
    abgelehnt = "abgelehnt"


class SessionStatus(str, enum.Enum):
    geplant = "geplant"
    bestaetigt = "bestaetigt"
    abgesagt = "abgesagt"
