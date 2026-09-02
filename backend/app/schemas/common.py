"""Shared response envelopes."""

from typing import Generic, TypeVar

from pydantic import BaseModel, Field

T = TypeVar("T")


class Page(BaseModel, Generic[T]):
    """Offset-paginated list response.

    Offset rather than cursor pagination: the dashboard needs jump-to-page and
    a total count, and at this data volume the cost of OFFSET is irrelevant.
    """

    items: list[T]
    total: int
    limit: int
    offset: int

    @property
    def has_more(self) -> bool:
        return self.offset + len(self.items) < self.total


class Message(BaseModel):
    message: str
    details: dict = Field(default_factory=dict)
