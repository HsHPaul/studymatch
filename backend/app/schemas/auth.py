# Schemas für Registrierung, Login und Token-Antwort.
# Pydantic validiert automatisch: ist die Email gültig? Sind alle Pflichtfelder da?
from pydantic import BaseModel, EmailStr, Field


class RegisterRequest(BaseModel):
    alias: str = Field(min_length=2, max_length=50)
    email: EmailStr
    password: str = Field(min_length=8)
    studiengang: str | None = None


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class PasswordResetRequest(BaseModel):
    email: EmailStr
    new_password: str = Field(min_length=8)
