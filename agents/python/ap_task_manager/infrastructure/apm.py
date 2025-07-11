"""
APM (Application Performance Monitoring) integration layer.

Provides abstraction for various APM providers including OpenTelemetry,
Prometheus, and custom implementations.
"""

import time
from abc import ABC, abstractmethod
from contextlib import contextmanager
from datetime import datetime
from enum import Enum
from typing import Dict, Any, Optional, Generator
import json
import logging

# Optional imports for actual APM providers
try:
    from opentelemetry import trace
    from opentelemetry.trace import Status, StatusCode
    from opentelemetry.sdk.trace import TracerProvider
    from opentelemetry.sdk.trace.export import BatchSpanProcessor, ConsoleSpanExporter
    from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
    HAS_OPENTELEMETRY = True
except ImportError:
    HAS_OPENTELEMETRY = False

try:
    from prometheus_client import Counter, Histogram, Gauge, CollectorRegistry
    HAS_PROMETHEUS = True
except ImportError:
    HAS_PROMETHEUS = False


logger = logging.getLogger(__name__)


class MetricType(Enum):
    """Types of metrics supported."""
    COUNTER = "counter"
    GAUGE = "gauge"
    HISTOGRAM = "histogram"


class APMSpan(ABC):
    """Abstract span for tracing."""
    
    @abstractmethod
    def set_attribute(self, key: str, value: Any) -> None:
        """Set an attribute on the span."""
        pass
    
    @abstractmethod
    def set_status(self, success: bool, message: str = "") -> None:
        """Set the span status."""
        pass
    
    @abstractmethod
    def add_event(self, name: str, attributes: Optional[Dict[str, Any]] = None) -> None:
        """Add an event to the span."""
        pass


class APMProvider(ABC):
    """Abstract base class for APM providers."""
    
    @abstractmethod
    @contextmanager
    def span(self, operation: str) -> Generator[APMSpan, None, None]:
        """Create a new span for tracing."""
        pass
    
    @abstractmethod
    async def record_metric(
        self,
        metric_type: MetricType,
        name: str,
        value: float,
        tags: Optional[Dict[str, str]] = None
    ) -> None:
        """Record a metric."""
        pass
    
    @abstractmethod
    async def flush(self) -> None:
        """Flush any pending data."""
        pass


class ConsoleAPMProvider(APMProvider):
    """Simple console-based APM provider for development."""
    
    def __init__(self, verbose: bool = True):
        self.verbose = verbose
        self.metrics = {}
    
    @contextmanager
    def span(self, operation: str) -> Generator['ConsoleAPMSpan', None, None]:
        """Create a console span."""
        span = ConsoleAPMSpan(operation, self.verbose)
        start_time = time.time()
        
        try:
            yield span
            span.set_status(True)
        except Exception as e:
            span.set_status(False, str(e))
            raise
        finally:
            duration = time.time() - start_time
            if self.verbose:
                status = "✓" if span.success else "✗"
                logger.info(f"[APM] {status} {operation} ({duration:.3f}s)")
                if span.attributes:
                    logger.debug(f"  Attributes: {json.dumps(span.attributes, indent=2)}")
    
    async def record_metric(
        self,
        metric_type: MetricType,
        name: str,
        value: float,
        tags: Optional[Dict[str, str]] = None
    ) -> None:
        """Record metric to console."""
        key = f"{name}:{json.dumps(tags or {}, sort_keys=True)}"
        
        if metric_type == MetricType.COUNTER:
            self.metrics[key] = self.metrics.get(key, 0) + value
        elif metric_type == MetricType.GAUGE:
            self.metrics[key] = value
        elif metric_type == MetricType.HISTOGRAM:
            if key not in self.metrics:
                self.metrics[key] = []
            self.metrics[key].append(value)
        
        if self.verbose:
            logger.info(f"[APM] Metric: {name}={value} ({metric_type.value}) tags={tags}")
    
    async def flush(self) -> None:
        """Print metrics summary."""
        if self.verbose and self.metrics:
            logger.info("[APM] Metrics Summary:")
            for key, value in self.metrics.items():
                logger.info(f"  {key}: {value}")


class ConsoleAPMSpan(APMSpan):
    """Console implementation of APM span."""
    
    def __init__(self, operation: str, verbose: bool):
        self.operation = operation
        self.verbose = verbose
        self.attributes = {}
        self.events = []
        self.success = True
        self.message = ""
    
    def set_attribute(self, key: str, value: Any) -> None:
        """Set span attribute."""
        self.attributes[key] = value
    
    def set_status(self, success: bool, message: str = "") -> None:
        """Set span status."""
        self.success = success
        self.message = message
    
    def add_event(self, name: str, attributes: Optional[Dict[str, Any]] = None) -> None:
        """Add span event."""
        self.events.append({
            "name": name,
            "timestamp": datetime.utcnow().isoformat(),
            "attributes": attributes or {}
        })
        if self.verbose:
            logger.debug(f"[APM] Event: {name} {attributes}")


class OpenTelemetryProvider(APMProvider):
    """OpenTelemetry APM provider."""
    
    def __init__(self, service_name: str = "ap-task-manager", endpoint: Optional[str] = None):
        if not HAS_OPENTELEMETRY:
            raise ImportError("opentelemetry-api and opentelemetry-sdk required")
        
        # Set up tracer
        provider = TracerProvider()
        
        # Add exporters
        if endpoint:
            otlp_exporter = OTLPSpanExporter(endpoint=endpoint, insecure=True)
            provider.add_span_processor(BatchSpanProcessor(otlp_exporter))
        else:
            # Console exporter for development
            console_exporter = ConsoleSpanExporter()
            provider.add_span_processor(BatchSpanProcessor(console_exporter))
        
        trace.set_tracer_provider(provider)
        self.tracer = trace.get_tracer(service_name)
        
        # Metrics storage (simplified - in production use proper metrics backend)
        self.metrics = {}
    
    @contextmanager
    def span(self, operation: str) -> Generator['OTelSpan', None, None]:
        """Create OpenTelemetry span."""
        with self.tracer.start_as_current_span(operation) as otel_span:
            span = OTelSpan(otel_span)
            yield span
    
    async def record_metric(
        self,
        metric_type: MetricType,
        name: str,
        value: float,
        tags: Optional[Dict[str, str]] = None
    ) -> None:
        """Record metric (simplified implementation)."""
        # In production, integrate with OpenTelemetry Metrics API
        key = f"{name}:{json.dumps(tags or {}, sort_keys=True)}"
        
        if metric_type == MetricType.COUNTER:
            self.metrics[key] = self.metrics.get(key, 0) + value
        elif metric_type == MetricType.GAUGE:
            self.metrics[key] = value
        elif metric_type == MetricType.HISTOGRAM:
            if key not in self.metrics:
                self.metrics[key] = []
            self.metrics[key].append(value)
    
    async def flush(self) -> None:
        """Flush telemetry data."""
        # Force flush of span processors
        provider = trace.get_tracer_provider()
        if hasattr(provider, 'force_flush'):
            provider.force_flush()


class OTelSpan(APMSpan):
    """OpenTelemetry span wrapper."""
    
    def __init__(self, otel_span):
        self.span = otel_span
    
    def set_attribute(self, key: str, value: Any) -> None:
        """Set span attribute."""
        self.span.set_attribute(key, value)
    
    def set_status(self, success: bool, message: str = "") -> None:
        """Set span status."""
        if success:
            self.span.set_status(Status(StatusCode.OK))
        else:
            self.span.set_status(Status(StatusCode.ERROR, message))
    
    def add_event(self, name: str, attributes: Optional[Dict[str, Any]] = None) -> None:
        """Add span event."""
        self.span.add_event(name, attributes=attributes or {})


class PrometheusProvider(APMProvider):
    """Prometheus metrics provider."""
    
    def __init__(self, registry: Optional[CollectorRegistry] = None):
        if not HAS_PROMETHEUS:
            raise ImportError("prometheus-client required")
        
        self.registry = registry or CollectorRegistry()
        self._metrics = {}
        
        # Pre-create common metrics
        self._ensure_metric(
            "task_operations_total",
            MetricType.COUNTER,
            "Total task operations",
            ["operation", "status"]
        )
        self._ensure_metric(
            "task_duration_seconds",
            MetricType.HISTOGRAM,
            "Task duration in seconds",
            ["priority", "status"]
        )
    
    def _ensure_metric(
        self,
        name: str,
        metric_type: MetricType,
        description: str,
        labels: list
    ):
        """Ensure a metric exists."""
        if name not in self._metrics:
            if metric_type == MetricType.COUNTER:
                self._metrics[name] = Counter(
                    name, description, labels, registry=self.registry
                )
            elif metric_type == MetricType.GAUGE:
                self._metrics[name] = Gauge(
                    name, description, labels, registry=self.registry
                )
            elif metric_type == MetricType.HISTOGRAM:
                self._metrics[name] = Histogram(
                    name, description, labels, registry=self.registry
                )
    
    @contextmanager
    def span(self, operation: str) -> Generator[APMSpan, None, None]:
        """Create a basic span (Prometheus doesn't have native tracing)."""
        span = ConsoleAPMSpan(operation, False)
        start_time = time.time()
        
        try:
            yield span
            self._metrics["task_operations_total"].labels(
                operation=operation, status="success"
            ).inc()
        except Exception:
            self._metrics["task_operations_total"].labels(
                operation=operation, status="error"
            ).inc()
            raise
        finally:
            duration = time.time() - start_time
            # Record operation duration if applicable
            if operation.startswith("task."):
                self._ensure_metric(
                    f"{operation.replace('.', '_')}_duration_seconds",
                    MetricType.HISTOGRAM,
                    f"Duration of {operation}",
                    []
                )
                self._metrics[f"{operation.replace('.', '_')}_duration_seconds"].observe(duration)
    
    async def record_metric(
        self,
        metric_type: MetricType,
        name: str,
        value: float,
        tags: Optional[Dict[str, str]] = None
    ) -> None:
        """Record Prometheus metric."""
        # Normalize metric name
        metric_name = name.replace(".", "_").replace("-", "_")
        
        # Get label names and values
        label_names = sorted(tags.keys()) if tags else []
        label_values = [tags[k] for k in label_names] if tags else []
        
        # Ensure metric exists
        if metric_name not in self._metrics:
            self._ensure_metric(
                metric_name,
                metric_type,
                f"Metric: {name}",
                label_names
            )
        
        # Record value
        metric = self._metrics[metric_name]
        if label_values:
            metric = metric.labels(*label_values)
        
        if metric_type == MetricType.COUNTER:
            metric.inc(value)
        elif metric_type == MetricType.GAUGE:
            metric.set(value)
        elif metric_type == MetricType.HISTOGRAM:
            metric.observe(value)
    
    async def flush(self) -> None:
        """Prometheus handles this automatically."""
        pass


def create_apm_provider(provider_type: str = "console", **kwargs) -> APMProvider:
    """Factory function to create APM providers."""
    providers = {
        "console": ConsoleAPMProvider,
        "opentelemetry": OpenTelemetryProvider,
        "prometheus": PrometheusProvider,
    }
    
    if provider_type not in providers:
        raise ValueError(f"Unknown provider type: {provider_type}")
    
    return providers[provider_type](**kwargs)