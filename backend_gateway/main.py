"""
Madhur-Trace Backend Gateway

Smart India Hackathon
Problem Statement: 26021
Honey Chain

Member 4:
Backend API Gateway
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .database import Base, engine
from . import models
from .routers import public, reports


# Create database tables
Base.metadata.create_all(bind=engine)


app = FastAPI(
    title="Madhur-Trace Backend Gateway",
    description=(
        "Backend API Gateway for Honey Chain - "
        "SIH Problem Statement 26021"
    ),
    version="1.0.0",
)


# Frontend development server
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://127.0.0.1:3000",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Register API routers
app.include_router(reports.router)
app.include_router(public.router)


@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": "madhur-trace-backend-gateway",
        "problem_statement": "26021",
    }