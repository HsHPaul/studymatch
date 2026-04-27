# Basis-Schema für alle Response-Schemas die ORM-Objekte serialisieren.
# Ersetzt das wiederholte model_config = {"from_attributes": True} in jeder Klasse.
from pydantic import BaseModel


class OrmBase(BaseModel):
    model_config = {"from_attributes": True}
