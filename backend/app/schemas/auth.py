# Schemas für Registrierung, Login und Token-Antwort.
# Pydantic validiert automatisch: ist die Email gültig? Sind alle Pflichtfelder da?
from pydantic import BaseModel, EmailStr


class RegisterRequest(BaseModel):
    alias: str
    email: EmailStr
    password: str
    studiengang: str | None = None


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
