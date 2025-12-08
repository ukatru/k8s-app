# Observability with Grafana Stack

This Helm chart is designed to work with the Grafana observability stack (Grafana, Prometheus, Tempo, Loki).

## Overview

The chart automatically configures your applications with:
- **Prometheus metrics** endpoints
- **Distributed tracing** configuration
- **Structured logging** (JSON format)
- **Standard labels** for service discovery

## Configuration

### Basic Setup

```yaml
observability:
  team: "platform"  # Team responsible for this service
  metrics:
    enabled: true
    port: 9090
    path: /metrics
  tracing:
    enabled: true
    sampleRate: "1.0"  # 0.0 to 1.0
  logging:
    enabled: true
    format: "json"  # json or text
```

## Environment Variables

The chart automatically sets these environment variables in your containers:

```yaml
APP_ENV: "production"          # From appSpec.env
APP_NAME: "my-app"             # From appSpec.name
APP_VERSION: "1.0.0"           # From appSpec.version
METRICS_PORT: "9090"           # Metrics endpoint port
METRICS_PATH: "/metrics"       # Metrics endpoint path
TRACING_ENABLED: "true"        # Enable tracing
TRACING_SAMPLE_RATE: "1.0"     # Trace sampling rate
LOG_FORMAT: "json"             # Log format
```

## Labels

All resources are labeled with standard Kubernetes and observability labels:

```yaml
# Standard Kubernetes labels
app.kubernetes.io/name: k8s-app
app.kubernetes.io/instance: my-app
app.kubernetes.io/version: 1.0.0
app.kubernetes.io/component: backend
app.kubernetes.io/part-of: SNOW123456
app.kubernetes.io/managed-by: Helm

# Observability labels
app.kubernetes.io/env: production
app.kubernetes.io/service: my-app
app.kubernetes.io/team: platform
```

## Integration with Grafana Stack

### Prometheus Metrics

Your application should expose metrics at the configured endpoint:

**Python (Flask/FastAPI):**
```python
from prometheus_client import Counter, Histogram, generate_latest
import os

# Read from environment
METRICS_PORT = int(os.getenv('METRICS_PORT', '9090'))
METRICS_PATH = os.getenv('METRICS_PATH', '/metrics')

# Define metrics
request_count = Counter('http_requests_total', 'Total HTTP requests')
request_duration = Histogram('http_request_duration_seconds', 'HTTP request duration')

# Expose metrics endpoint
@app.route(METRICS_PATH)
def metrics():
    return generate_latest()
```

**Java (Spring Boot):**
```xml
<!-- pom.xml -->
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

```yaml
# application.yml
management:
  endpoints:
    web:
      exposure:
        include: prometheus,health
  metrics:
    export:
      prometheus:
        enabled: true
```

**.NET (ASP.NET Core):**
```csharp
// Program.cs
using Prometheus;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddMetrics();

var app = builder.Build();
app.UseMetricServer();  // Exposes /metrics
app.UseHttpMetrics();
```

### ServiceMonitor for Prometheus

Create a ServiceMonitor to scrape metrics:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: my-app
  labels:
    app: my-app
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: k8s-app
      app.kubernetes.io/instance: my-app
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
```

### Tempo Tracing

Configure your application to send traces to Tempo:

**Python (OpenTelemetry):**
```python
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
import os

# Read from environment
tracing_enabled = os.getenv('TRACING_ENABLED', 'false') == 'true'
sample_rate = float(os.getenv('TRACING_SAMPLE_RATE', '1.0'))

if tracing_enabled:
    provider = TracerProvider()
    processor = BatchSpanProcessor(
        OTLPSpanExporter(endpoint="tempo:4317")
    )
    provider.add_span_processor(processor)
    trace.set_tracer_provider(provider)
```

**Java (Spring Boot + OpenTelemetry):**
```yaml
# application.yml
management:
  tracing:
    sampling:
      probability: ${TRACING_SAMPLE_RATE:1.0}
  otlp:
    tracing:
      endpoint: http://tempo:4318/v1/traces
```

**.NET (OpenTelemetry):**
```csharp
// Program.cs
using OpenTelemetry.Trace;

builder.Services.AddOpenTelemetry()
    .WithTracing(tracerProviderBuilder =>
    {
        tracerProviderBuilder
            .AddAspNetCoreInstrumentation()
            .AddOtlpExporter(options =>
            {
                options.Endpoint = new Uri("http://tempo:4317");
            });
    });
```

### Loki Logging

Configure structured JSON logging:

**Python:**
```python
import logging
import json
import os

log_format = os.getenv('LOG_FORMAT', 'json')

if log_format == 'json':
    logging.basicConfig(
        format='%(message)s',
        handlers=[logging.StreamHandler()]
    )
    
    # Use structured logging
    logger.info(json.dumps({
        'level': 'info',
        'message': 'Request processed',
        'app_name': os.getenv('APP_NAME'),
        'app_version': os.getenv('APP_VERSION'),
        'env': os.getenv('APP_ENV')
    }))
```

**Java (Logback):**
```xml
<!-- logback-spring.xml -->
<configuration>
    <appender name="JSON" class="ch.qos.logback.core.ConsoleAppender">
        <encoder class="net.logstash.logback.encoder.LogstashEncoder">
            <customFields>{"app":"${APP_NAME}","version":"${APP_VERSION}","env":"${APP_ENV}"}</customFields>
        </encoder>
    </appender>
    <root level="INFO">
        <appender-ref ref="JSON" />
    </root>
</configuration>
```

**.NET (Serilog):**
```csharp
// Program.cs
using Serilog;

Log.Logger = new LoggerConfiguration()
    .WriteTo.Console(new JsonFormatter())
    .Enrich.WithProperty("app_name", Environment.GetEnvironmentVariable("APP_NAME"))
    .Enrich.WithProperty("app_version", Environment.GetEnvironmentVariable("APP_VERSION"))
    .Enrich.WithProperty("env", Environment.GetEnvironmentVariable("APP_ENV"))
    .CreateLogger();
```

## Grafana Dashboards

### Service Dashboard Query Examples

**Request Rate:**
```promql
rate(http_requests_total{
  app_kubernetes_io_name="k8s-app",
  app_kubernetes_io_instance="my-app"
}[5m])
```

**Error Rate:**
```promql
rate(http_requests_total{
  app_kubernetes_io_name="k8s-app",
  app_kubernetes_io_instance="my-app",
  status=~"5.."
}[5m])
```

**Request Duration (p95):**
```promql
histogram_quantile(0.95,
  rate(http_request_duration_seconds_bucket{
    app_kubernetes_io_name="k8s-app",
    app_kubernetes_io_instance="my-app"
  }[5m])
)
```

**Pod CPU Usage:**
```promql
rate(container_cpu_usage_seconds_total{
  pod=~"my-app-.*"
}[5m])
```

**Pod Memory Usage:**
```promql
container_memory_working_set_bytes{
  pod=~"my-app-.*"
}
```

### Loki Log Queries

**All logs for service:**
```logql
{app_kubernetes_io_instance="my-app"}
```

**Error logs:**
```logql
{app_kubernetes_io_instance="my-app"} |= "error" | json
```

**Logs by environment:**
```logql
{app_kubernetes_io_env="production"} | json
```

## Complete Example

### values.yaml

```yaml
appSpec:
  name: "my-api"
  version: "1.0.0"
  env: "production"
  language: "python"
  image: "registry/my-api:1.0.0"

observability:
  team: "platform"
  metrics:
    enabled: true
    port: 9090
    path: /metrics
  tracing:
    enabled: true
    sampleRate: "0.5"  # Sample 50% of traces
  logging:
    enabled: true
    format: "json"

resources:
  plan: "medium"
```

### ServiceMonitor

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: my-api
  namespace: production
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: k8s-app
      app.kubernetes.io/instance: my-api
  endpoints:
  - port: http
    path: /metrics
    interval: 15s
```

### Grafana Dashboard Variables

```
# Service selector
app_kubernetes_io_instance="$service"

# Environment selector
app_kubernetes_io_env="$environment"

# Team selector
app_kubernetes_io_team="$team"
```

## Best Practices

### 1. Use Consistent Labels

The chart automatically adds standard labels. Use them in your queries:

```promql
# Good
{app_kubernetes_io_instance="my-app"}

# Bad
{app="my-app"}  # Non-standard label
```

### 2. Sample Traces Appropriately

High-traffic services should use lower sample rates:

```yaml
observability:
  tracing:
    sampleRate: "0.1"  # 10% for high-traffic services
```

### 3. Use Structured Logging

Always use JSON format for better parsing:

```yaml
observability:
  logging:
    format: "json"
```

### 4. Add Custom Metrics

Instrument your code with business metrics:

```python
# Python
from prometheus_client import Counter

orders_total = Counter('orders_total', 'Total orders processed')
orders_total.inc()
```

### 5. Use Trace Context

Propagate trace context in HTTP headers:

```python
# Python
from opentelemetry.propagate import inject

headers = {}
inject(headers)
requests.get('http://other-service', headers=headers)
```

## Troubleshooting

### Metrics Not Appearing

1. Check metrics endpoint is accessible:
```bash
kubectl port-forward svc/my-app 9090:9090
curl http://localhost:9090/metrics
```

2. Verify ServiceMonitor is created and targets are up in Prometheus

3. Check labels match between Service and ServiceMonitor

### Traces Not Appearing

1. Verify `TRACING_ENABLED=true` in pod:
```bash
kubectl exec -it my-app-pod -- env | grep TRACING
```

2. Check Tempo endpoint is reachable from pod

3. Verify trace exporter configuration

### Logs Not Structured

1. Check `LOG_FORMAT=json` in pod:
```bash
kubectl exec -it my-app-pod -- env | grep LOG_FORMAT
```

2. Verify logging library is configured for JSON output

3. Check Loki is parsing JSON correctly

## Summary

The chart provides:
- ✅ **Standard labels** for Grafana queries
- ✅ **Environment variables** for configuration
- ✅ **Prometheus metrics** integration
- ✅ **Tempo tracing** support
- ✅ **Loki logging** with JSON format
- ✅ **Language-specific** defaults

Just configure `observability` in your values and instrument your application! 🚀
