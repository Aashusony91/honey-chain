"""
Madhur-Trace Database Configuration

Member 4:
Backend API Gateway

This module provides the database connection and session management
for the backend gateway.
"""

from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker


# SQLite database for local development.
# Later this can be changed to PostgreSQL through an environment variable.
DATABASE_URL = "sqlite:///./madhur_trace.db"


engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False},
)


SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)


Base = declarative_base()


def get_db():
    """
    Provide a database session to FastAPI endpoints.
    """
    db = SessionLocal()

    try:
        yield db
    finally:
        db.close()