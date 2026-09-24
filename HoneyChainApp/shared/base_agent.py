"""
shared/base_agent.py — Abstract Base Agent for Honey Chain
===========================================================
All agents in the supply-chain pipeline inherit from this class.
"""

from __future__ import annotations

from abc import ABC, abstractmethod

from shared.schemas import AgentRequest, AgentResponse


class BaseAgent(ABC):
    """
    Abstract base class for all agents in the Honey Chain pipeline.

    Subclasses must implement:
        - ``process()``: Handle an incoming ``AgentRequest`` and return ``AgentResponse``.
        - ``get_capabilities()``: Return a list of action strings this agent supports.
    """

    @abstractmethod
    async def process(self, request: AgentRequest) -> AgentResponse:
        """
        Process an incoming agent request and produce a response.

        Args:
            request: The ``AgentRequest`` envelope containing the action
                     and payload to be processed.

        Returns:
            An ``AgentResponse`` with the updated payload or error details.
        """
        ...

    @abstractmethod
    def get_capabilities(self) -> list[str]:
        """
        Return the list of action verbs this agent can handle.

        Example:
            ``["mint_batch", "record_lab_cert", "split_batch_token"]``
        """
        ...
