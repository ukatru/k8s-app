# Custom Overrides Guide

The chart supports overriding any language-specific default while still using a supported language. You don't need to define a custom language - just override the specific settings you want to change!

## How It Works

The chart uses a **merge strategy** where user values take precedence over language defaults:

```
User Values + Language Defaults = Final Configuration
(higher priority)  (lower priority)
```

This is similar to Timoni's approach:
```cue
// Timoni
let _liveness = #ProbesMerge & {
  _userProbe: _config.lifecycle.livenessProbe  // User values
  _def: #livenessProbesDefaults[_config.appSpec.language]  // Defaults
}
```

## Override Options

### 1. Override Individual Probe Settings

Keep the language but customize specific probe values:

```yaml
appSpec:
  language: "java"  # Still use Java language

lifecycle:
  livenessProbe:
    # Override just what you need
    path: /actuator/health/custom-liveness
    initialDelaySeconds: 90
    # Other settings (port, timeoutSeconds, etc.) use Java defaults
  
  readinessProbe:
    # Override just the failure threshold
    failureThreshold: 5
    # path, port, delays use Java defaults
```

**Result:**
- Path: `/actuator/health/custom-liveness` (your override)
- Initial delay: `90s` (your override)
- Port: `8080` (Java default)
- Timeout: `3s` (Java default)
- Period: `10s` (Java default)

### 2. Override Resource Plans with Custom Values

Use `plan: custom` to specify exact resource values:

```yaml
appSpec:
  language: "java"  # Still use Java language

resources:
  plan: "custom"  # Don't use t-shirt sizing
  
  # Specify exact values
  memory:
    minMB: 3072    # 3GB request
    maxMB: 6144    # 6GB limit
  cpu:
    minMilliCores: 1500  # 1.5 CPU request
    maxMilliCores: 3000  # 3 CPU limit
```

**Result:**
- Resources: Your custom values
- Probes: Still use Java defaults
- Env vars: Still use Java defaults

### 3. Mix and Match

Override probes AND resources:

```yaml
appSpec:
  language: "python"

resources:
  plan: "custom"
  memory:
    minMB: 1024
    maxMB: 2048
  cpu:
    minMilliCores: 500
    maxMilliCores: 1000

lifecycle:
  livenessProbe:
    path: /custom/health
    initialDelaySeconds: 45
  readinessProbe:
    path: /custom/ready
```

## Complete Examples

### Example 1: Java with Custom Startup Time

```yaml
appSpec:
  name: "slow-java-app"
  language: "java"
  image: "registry/slow-java-app:1.0.0"

resources:
  plan: "large"  # Use Java large plan

lifecycle:
  # Only override startup - it takes longer
  startupProbe:
    failureThreshold: 120  # 20 minutes (120 * 10s)
  # liveness and readiness use Java defaults
```

### Example 2: Python with Exact Resources

```yaml
appSpec:
  name: "python-worker"
  language: "python"
  image: "registry/python-worker:1.0.0"

resources:
  plan: "custom"  # Exact resources needed
  memory:
    minMB: 768
    maxMB: 1536
  cpu:
    minMilliCores: 300
    maxMilliCores: 600

# Probes use Python defaults
```

### Example 3: SPA with Custom Port

```yaml
appSpec:
  name: "react-app"
  language: "spa"
  image: "registry/react-app:1.0.0"

resources:
  plan: "small"  # Use SPA small plan

lifecycle:
  # Override port for all probes
  livenessProbe:
    port: 3000  # Custom port
  readinessProbe:
    port: 3000  # Custom port
  # probeType (tcp), delays, etc. use SPA defaults
```

### Example 4: .NET with Custom Health Endpoints

```yaml
appSpec:
  name: "dotnet-api"
  language: "dotnet"
  image: "registry/dotnet-api:1.0.0"

resources:
  plan: "medium"  # Use .NET medium plan

lifecycle:
  livenessProbe:
    path: /api/health/live  # Custom path
  readinessProbe:
    path: /api/health/ready  # Custom path
  startupProbe:
    path: /api/health/startup  # Custom path
  # port, delays, timeouts use .NET defaults
```

## What Can Be Overridden?

### Probe Settings

Any probe field can be overridden:

```yaml
lifecycle:
  livenessProbe:
    probeType: "http"  # or tcp, exec, grpc
    path: "/custom/path"
    port: 9090
    initialDelaySeconds: 60
    timeoutSeconds: 5
    periodSeconds: 15
    successThreshold: 1
    failureThreshold: 5
    exec:  # For exec probes
      - /bin/sh
      - -c
      - "custom command"
```

### Resource Plans

Use `custom` plan for exact values:

```yaml
resources:
  plan: "custom"
  memory:
    minMB: 2048
    maxMB: 4096
  cpu:
    minMilliCores: 1000
    maxMilliCores: 2000
```

### Environment Variables

Override or add to language defaults:

```yaml
env:
  # Override Java default
  JAVA_OPTS: "-Xmx5g -Xms3g -XX:+UseG1GC"
  # Add custom vars
  CUSTOM_VAR: "value"
```

## Testing Overrides

### 1. Dry Run

```bash
helm install test ./k8s-app \
  --values custom-overrides.yaml \
  --dry-run --debug
```

### 2. Check Specific Values

```bash
# Check probes
helm template test ./k8s-app \
  --values custom-overrides.yaml \
  --show-only templates/deployment.yaml | \
  grep -A 10 "livenessProbe:"

# Check resources
helm template test ./k8s-app \
  --values custom-overrides.yaml \
  --show-only templates/deployment.yaml | \
  grep -A 6 "resources:"
```

## Best Practices

### 1. Override Only What's Needed

**Good:**
```yaml
lifecycle:
  livenessProbe:
    initialDelaySeconds: 90  # Just this
```

**Avoid:**
```yaml
lifecycle:
  livenessProbe:
    probeType: http  # Don't repeat defaults
    path: /actuator/health/liveness
    port: 8080
    initialDelaySeconds: 90
    timeoutSeconds: 3
    # ... all fields
```

### 2. Document Why You Override

```yaml
lifecycle:
  startupProbe:
    # This app has a 5-minute initialization process
    failureThreshold: 60  # 10 minutes total
```

### 3. Use Custom Plan Sparingly

Prefer t-shirt sizes when possible:

```yaml
# Good - use standard plan
resources:
  plan: "large"

# Only when standard plans don't fit
resources:
  plan: "custom"
  # Specific requirements...
```

### 4. Test in Non-Prod First

Always test custom overrides in dev/staging before production.

## Comparison: T-Shirt vs Custom

### Using T-Shirt Sizes (Recommended)

```yaml
appSpec:
  language: "java"
resources:
  plan: "large"  # Simple, predictable
```

**Pros:**
- ✅ Consistent across apps
- ✅ Easy to understand
- ✅ Tested defaults
- ✅ Language-optimized

**Cons:**
- ⚠️ Less flexibility

### Using Custom Resources

```yaml
appSpec:
  language: "java"
resources:
  plan: "custom"
  memory: {minMB: 3072, maxMB: 6144}
  cpu: {minMilliCores: 1500, maxMilliCores: 3000}
```

**Pros:**
- ✅ Exact control
- ✅ Optimize for specific needs

**Cons:**
- ⚠️ More complex
- ⚠️ Need to tune manually
- ⚠️ May not be optimal

## Summary

The chart supports flexible overrides:

- ✅ **Override individual settings** while keeping language defaults
- ✅ **Use custom resource plans** instead of t-shirt sizes
- ✅ **Mix and match** - override probes, resources, env vars independently
- ✅ **Simple merge strategy** - user values win

You don't need to define custom languages - just override what you need! 🚀

See [examples/java-app-custom-overrides.yaml](examples/java-app-custom-overrides.yaml) for a complete example.
