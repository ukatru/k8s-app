# Language-Specific Features

This Helm chart automatically configures resources and health probes based on the application language specified in `appSpec.language`.

## Overview

Simply set `appSpec.language` to one of: `python`, `java`, `dotnet`, or `spa`, and the chart will automatically apply language-specific defaults for:

- **Resource plans** (CPU and memory)
- **Health probe endpoints** and timings
- **Environment variables**

You can override any default by explicitly setting values in your `values.yaml`.

---

## Python Applications

### Configuration

```yaml
appSpec:
  language: "python"
```

### Resource Plans

Python applications use moderate resource requirements:

| Plan | CPU Request | CPU Limit | Memory Request | Memory Limit |
|------|-------------|-----------|----------------|--------------|
| **small** | 250m | 500m | 256Mi | 512Mi |
| **medium** | 500m | 1000m | 512Mi | 1Gi |
| **large** | 1000m | 2000m | 1Gi | 2Gi |
| **huge** | 2000m | 4000m | 2Gi | 4Gi |

### Health Probes

**Default Endpoints:**
- Liveness: `GET /health`
- Readiness: `GET /ready`
- Startup: `GET /startup`

**Default Timings:**
```yaml
livenessProbe:
  initialDelaySeconds: 30
  timeoutSeconds: 1
  periodSeconds: 10
  failureThreshold: 3

readinessProbe:
  initialDelaySeconds: 5
  timeoutSeconds: 1
  periodSeconds: 5
  failureThreshold: 3

startupProbe:
  initialDelaySeconds: 0
  timeoutSeconds: 1
  periodSeconds: 10
  failureThreshold: 30  # 5 minutes total
```

### Environment Variables

Automatically set:
```yaml
PYTHONUNBUFFERED: "1"
PYTHONDONTWRITEBYTECODE: "1"
```

### Example

See [examples/python-app.yaml](examples/python-app.yaml)

---

## Java Applications

### Configuration

```yaml
appSpec:
  language: "java"
```

### Resource Plans

Java applications need more memory for the JVM:

| Plan | CPU Request | CPU Limit | Memory Request | Memory Limit |
|------|-------------|-----------|----------------|--------------|
| **small** | 500m | 1000m | 512Mi | 1Gi |
| **medium** | 1000m | 2000m | 1Gi | 2Gi |
| **large** | 2000m | 4000m | 2Gi | 4Gi |
| **huge** | 4000m | 8000m | 4Gi | 8Gi |

**Note:** Java plans are 2x the memory of Python plans at each tier.

### Health Probes

**Default Endpoints** (Spring Boot Actuator):
- Liveness: `GET /actuator/health/liveness`
- Readiness: `GET /actuator/health/readiness`
- Startup: `GET /actuator/health/liveness`

**Default Timings:**
```yaml
livenessProbe:
  initialDelaySeconds: 60  # Longer for JVM startup
  timeoutSeconds: 3
  periodSeconds: 10
  failureThreshold: 3

readinessProbe:
  initialDelaySeconds: 30
  timeoutSeconds: 3
  periodSeconds: 5
  failureThreshold: 3

startupProbe:
  initialDelaySeconds: 0
  timeoutSeconds: 3
  periodSeconds: 10
  failureThreshold: 60  # 10 minutes total
```

**Note:** Java apps get longer startup times due to JVM initialization.

### Environment Variables

Automatically set:
```yaml
JAVA_OPTS: "-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"
```

### Spring Boot Actuator Setup

For health probes to work, ensure your Spring Boot application has:

```xml
<!-- pom.xml -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

```yaml
# application.yml
management:
  endpoint:
    health:
      probes:
        enabled: true
  health:
    livenessState:
      enabled: true
    readinessState:
      enabled: true
```

### Example

See [examples/java-app.yaml](examples/java-app.yaml)

---

## .NET Applications

### Configuration

```yaml
appSpec:
  language: "dotnet"
```

### Resource Plans

.NET applications use moderate resources with slightly higher memory than Python:

| Plan | CPU Request | CPU Limit | Memory Request | Memory Limit |
|------|-------------|-----------|----------------|--------------|
| **small** | 250m | 500m | 384Mi | 768Mi |
| **medium** | 500m | 1000m | 768Mi | 1536Mi |
| **large** | 1000m | 2000m | 1536Mi | 3Gi |
| **huge** | 2000m | 4000m | 3Gi | 6Gi |

### Health Probes

**Default Endpoints** (ASP.NET Core Health Checks):
- Liveness: `GET /health/live`
- Readiness: `GET /health/ready`
- Startup: `GET /health/startup`

**Default Timings:**
```yaml
livenessProbe:
  initialDelaySeconds: 30
  timeoutSeconds: 2
  periodSeconds: 10
  failureThreshold: 3

readinessProbe:
  initialDelaySeconds: 10
  timeoutSeconds: 2
  periodSeconds: 5
  failureThreshold: 3

startupProbe:
  initialDelaySeconds: 0
  timeoutSeconds: 2
  periodSeconds: 10
  failureThreshold: 30  # 5 minutes total
```

### Environment Variables

Automatically set:
```yaml
DOTNET_RUNNING_IN_CONTAINER: "true"
DOTNET_SYSTEM_GLOBALIZATION_INVARIANT: "false"
```

### ASP.NET Core Health Checks Setup

For health probes to work, configure your ASP.NET Core application:

```csharp
// Program.cs or Startup.cs
builder.Services.AddHealthChecks();

app.MapHealthChecks("/health/live", new HealthCheckOptions
{
    Predicate = _ => false  // Liveness - no checks, just responds
});

app.MapHealthChecks("/health/ready", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("ready")
});

app.MapHealthChecks("/health/startup", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("startup")
});
```

### Example

See [examples/dotnet-app.yaml](examples/dotnet-app.yaml)

---

## SPA (Single Page Application)

### Configuration

```yaml
appSpec:
  language: "spa"
```

### Resource Plans

SPAs need minimal resources since they serve static content:

| Plan | CPU Request | CPU Limit | Memory Request | Memory Limit |
|------|-------------|-----------|----------------|--------------|
| **small** | 100m | 200m | 128Mi | 256Mi |
| **medium** | 200m | 500m | 256Mi | 512Mi |
| **large** | 500m | 1000m | 512Mi | 1Gi |
| **huge** | 1000m | 2000m | 1Gi | 2Gi |

**Note:** SPA plans use minimal resources compared to backend services.

### Health Probes

**Default Type:** TCP Socket (no HTTP endpoints needed)

**Default Port:** 8080

**Default Timings:**
```yaml
livenessProbe:
  tcpSocket:
    port: 8080
  initialDelaySeconds: 10
  timeoutSeconds: 1
  periodSeconds: 10
  failureThreshold: 3

readinessProbe:
  tcpSocket:
    port: 8080
  initialDelaySeconds: 5
  timeoutSeconds: 1
  periodSeconds: 5
  failureThreshold: 3

startupProbe:
  tcpSocket:
    port: 8080
  initialDelaySeconds: 0
  timeoutSeconds: 1
  periodSeconds: 5
  failureThreshold: 12  # 1 minute total
```

**Note:** SPAs use TCP probes because they don't have health check endpoints - they just serve static files.

### Environment Variables

Automatically set:
```yaml
# No language-specific env vars for SPAs
# Use standard observability env vars
```

### Common SPA Frameworks

This configuration works well with:
- **React** (Create React App, Next.js static export, Vite)
- **Vue.js** (Vue CLI, Nuxt.js static)
- **Angular** (Angular CLI)
- **Svelte** (SvelteKit static)
- **Static site generators** (Gatsby, Hugo, Jekyll)

### Nginx Configuration

Most SPAs are served by nginx. Example Dockerfile:

```dockerfile
# Build stage
FROM node:18 AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
```

Example `nginx.conf`:

```nginx
server {
    listen 8080;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # SPA routing - serve index.html for all routes
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
```

### Ingress Configuration

SPAs often need special ingress configuration for client-side routing:

```yaml
ingress:
  enabled: true
  annotations:
    # Serve index.html for all routes (client-side routing)
    nginx.ingress.kubernetes.io/configuration-snippet: |
      try_files $uri $uri/ /index.html;
    # Enable gzip compression
    nginx.ingress.kubernetes.io/enable-compression: "true"
    # Force HTTPS
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
```

### Example

See [examples/spa-app.yaml](examples/spa-app.yaml)

---

## Overriding Defaults

You can override any language-specific default in your `values.yaml`:

### Override Resource Plan

```yaml
appSpec:
  language: "java"

resources:
  plan: "custom"
  memory:
    minMB: 2048
    maxMB: 4096
  cpu:
    minMilliCores: 1000
    maxMilliCores: 2000
```

### Override Probe Endpoints

```yaml
appSpec:
  language: "python"

lifecycle:
  livenessProbe:
    path: "/custom/health"  # Override default /health
    port: 9090              # Override default 8080
    initialDelaySeconds: 60  # Override default 30
```

### Override Environment Variables

```yaml
appSpec:
  language: "java"

env:
  JAVA_OPTS: "-Xmx4g -XX:+UseG1GC"  # Override default
```

---

## Comparison Table

| Feature | Python | Java | .NET | SPA |
|---------|--------|------|------|-----|
| **Small Plan Memory** | 256Mi-512Mi | 512Mi-1Gi | 384Mi-768Mi | 128Mi-256Mi |
| **Small Plan CPU** | 250m-500m | 500m-1000m | 250m-500m | 100m-200m |
| **Probe Type** | HTTP | HTTP | HTTP | TCP |
| **Liveness** | `/health` | `/actuator/health/liveness` | `/health/live` | TCP:8080 |
| **Startup Delay** | 30s | 60s | 30s | 10s |
| **Startup Timeout** | 5min | 10min | 5min | 1min |
| **Auto Env Vars** | Python-specific | JVM-specific | .NET-specific | None |

---

## Best Practices

### 1. Use Language-Specific Defaults

Let the chart configure resources and probes automatically:

```yaml
appSpec:
  language: "java"  # That's it!
resources:
  plan: "medium"    # Automatically gets Java medium resources
```

### 2. Only Override When Necessary

Only specify probe settings if you need to change them:

```yaml
lifecycle:
  livenessProbe:
    path: "/custom/health"  # Only override what's different
    # Other settings use language defaults
```

### 3. Test Your Health Endpoints

Ensure your application implements the expected health check endpoints:

```bash
# Python
curl http://localhost:8080/health
curl http://localhost:8080/ready

# Java (Spring Boot)
curl http://localhost:8080/actuator/health/liveness
curl http://localhost:8080/actuator/health/readiness

# .NET (ASP.NET Core)
curl http://localhost:8080/health/live
curl http://localhost:8080/health/ready
```

### 4. Monitor Startup Times

If your app takes longer to start, increase `failureThreshold`:

```yaml
lifecycle:
  startupProbe:
    failureThreshold: 90  # 15 minutes (90 * 10s period)
```

### 5. Adjust Resources Based on Load

Start with a plan, then adjust based on actual usage:

```yaml
resources:
  plan: "medium"  # Start here
  autoscaling:
    enabled: true
    minInstances: 2
    maxInstances: 20
```

---

## Troubleshooting

### Pods Failing Health Checks

**Symptom:** Pods are restarting frequently

**Solution:**
1. Check if your app implements the health endpoints
2. Increase `initialDelaySeconds` if app needs more startup time
3. Check logs: `kubectl logs -f <pod-name>`

### Out of Memory Errors

**Symptom:** Pods are OOMKilled

**Solution:**
1. Increase resource plan: `medium` → `large`
2. Or use custom plan with more memory
3. For Java, adjust `JAVA_OPTS` heap size

### Slow Startup

**Symptom:** Pods take too long to become ready

**Solution:**
1. Increase `startupProbe.failureThreshold`
2. For Java, consider using `startupProbe` with higher timeout
3. Optimize application startup code

---

## Adding New Languages

To add support for a new language:

1. Add resource plan in `templates/_plans.tpl`:
```yaml
{{- define "k8s-app.plans.golang" -}}
{{- if eq .plan "small" }}
requests:
  cpu: 100m
  memory: 128Mi
# ...
{{- end }}
```

2. Add probe defaults in `templates/_probes.tpl`:
```yaml
{{- define "k8s-app.probes.golang.defaults" -}}
liveness:
  path: /healthz
  port: 8080
# ...
{{- end }}
```

3. Add environment variables in `templates/_helpers.tpl`:
```yaml
{{- else if eq .Values.appSpec.language "golang" }}
- name: GOMAXPROCS
  value: "2"
{{- end }}
```

4. Update documentation and examples

---

## Summary

Language-specific features make it easy to deploy applications with sensible defaults:

- ✅ **Automatic resource sizing** based on language requirements
- ✅ **Standard health check endpoints** for each framework
- ✅ **Optimized startup times** for each runtime
- ✅ **Framework-specific environment variables**
- ✅ **Easy to override** when needed

Just set `appSpec.language` and you're ready to go! 🚀
