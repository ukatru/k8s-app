# Adding New Languages

The chart uses a dynamic map-based approach for language-specific configurations, similar to Timoni's CUE approach. This makes adding new languages extremely simple - just add entries to the maps!

## Architecture

Instead of hardcoded `if/else` chains, we use:
- **Map-based lookups** for probe and resource defaults
- **Dynamic merging** of user values with language defaults
- **Fallback to Python** if language not found

This is similar to Timoni's approach:
```cue
// Timoni CUE
let _liveness = #ProbesMerge & {
  _userProbe: _config.lifecycle.livenessProbe
  _def: #livenessProbesDefaults[_config.appSpec.language]
}
```

```yaml
# Helm equivalent
{{- $merged := include "k8s-app.mergeProbe" (dict 
  "defaultsTemplate" "k8s-app.livenessProbeDefaults" 
  "user" .Values.lifecycle.livenessProbe 
  "language" .Values.appSpec.language) | fromYaml }}
```

## How to Add a New Language

### Step 1: Add Probe Defaults

Edit `templates/_probe-defaults.tpl` and add your language to each map:

```yaml
{{- define "k8s-app.livenessProbeDefaults" -}}
# ... existing languages ...
golang:  # NEW LANGUAGE
  probeType: http
  path: /healthz
  port: 8080
  initialDelaySeconds: 15
  timeoutSeconds: 1
  periodSeconds: 10
  successThreshold: 1
  failureThreshold: 3
{{- end }}

{{- define "k8s-app.readinessProbeDefaults" -}}
# ... existing languages ...
golang:  # NEW LANGUAGE
  probeType: http
  path: /readyz
  port: 8080
  initialDelaySeconds: 5
  timeoutSeconds: 1
  periodSeconds: 5
  successThreshold: 1
  failureThreshold: 3
{{- end }}

{{- define "k8s-app.startupProbeDefaults" -}}
# ... existing languages ...
golang:  # NEW LANGUAGE
  probeType: http
  path: /healthz
  port: 8080
  initialDelaySeconds: 0
  timeoutSeconds: 1
  periodSeconds: 5
  successThreshold: 1
  failureThreshold: 20
{{- end }}
```

### Step 2: Add Resource Plans

Edit `templates/_plan-defaults.tpl` and add your language:

```yaml
{{- define "k8s-app.resourcePlanDefaults" -}}
# ... existing languages ...
golang:  # NEW LANGUAGE
  small:
    requests: {cpu: "100m", memory: "128Mi"}
    limits: {cpu: "250m", memory: "256Mi"}
  medium:
    requests: {cpu: "250m", memory: "256Mi"}
    limits: {cpu: "500m", memory: "512Mi"}
  large:
    requests: {cpu: "500m", memory: "512Mi"}
    limits: {cpu: "1000m", memory: "1Gi"}
  huge:
    requests: {cpu: "1000m", memory: "1Gi"}
    limits: {cpu: "2000m", memory: "2Gi"}
{{- end }}
```

### Step 3: Add Language-Specific Env Vars (Optional)

Edit `templates/_helpers.tpl` if you need language-specific environment variables:

```yaml
{{- define "k8s-app.languageEnv" -}}
# ... existing languages ...
{{- else if eq .Values.appSpec.language "golang" }}
- name: GOMAXPROCS
  value: "2"
- name: GOMEMLIMIT
  value: "512MiB"
{{- end }}
{{- end }}
```

### Step 4: Update Documentation

Add your language to:
1. `values.yaml` - Add to language comment
2. `LANGUAGE-SPECIFIC-FEATURES.md` - Add full section
3. `examples/` - Create example file

### Step 5: Test

```bash
# Create test values
cat > test-golang.yaml <<EOF
appSpec:
  name: "go-api"
  language: "golang"
  image: "registry/go-api:1.0.0"
resources:
  plan: "small"
EOF

# Test rendering
helm template test /home/ukatru/src/github/k8s-app \
  --values test-golang.yaml \
  --show-only templates/deployment.yaml

# Verify probes use /healthz and /readyz
# Verify resources use golang small plan
```

## Complete Example: Adding Rust

### 1. Probe Defaults

```yaml
# templates/_probe-defaults.tpl
rust:
  probeType: http
  path: /health
  port: 8080
  initialDelaySeconds: 10
  timeoutSeconds: 1
  periodSeconds: 10
  successThreshold: 1
  failureThreshold: 3
```

### 2. Resource Plans

```yaml
# templates/_plan-defaults.tpl
rust:
  small:
    requests: {cpu: "100m", memory: "64Mi"}
    limits: {cpu: "200m", memory: "128Mi"}
  medium:
    requests: {cpu: "200m", memory: "128Mi"}
    limits: {cpu: "500m", memory: "256Mi"}
  large:
    requests: {cpu: "500m", memory: "256Mi"}
    limits: {cpu: "1000m", memory: "512Mi"}
  huge:
    requests: {cpu: "1000m", memory: "512Mi"}
    limits: {cpu: "2000m", memory: "1Gi"}
```

### 3. Environment Variables

```yaml
# templates/_helpers.tpl
{{- else if eq .Values.appSpec.language "rust" }}
- name: RUST_LOG
  value: "info"
- name: RUST_BACKTRACE
  value: "1"
```

### 4. Usage

```yaml
appSpec:
  name: "rust-service"
  language: "rust"  # That's it!
  image: "registry/rust-service:1.0.0"
resources:
  plan: "small"  # Uses Rust small plan automatically
```

## Benefits of This Approach

### 1. No Code Changes Needed

Adding a language doesn't require changing any logic:

**Before (hardcoded):**
```yaml
{{- if eq .Values.appSpec.language "python" }}
  # python config
{{- else if eq .Values.appSpec.language "java" }}
  # java config
{{- else if eq .Values.appSpec.language "dotnet" }}
  # dotnet config
{{- else if eq .Values.appSpec.language "NEW_LANG" }}  # ADD THIS
  # new lang config
{{- end }}
```

**After (map-based):**
```yaml
# Just add to the map - no logic changes!
{{- define "k8s-app.livenessProbeDefaults" -}}
python: {...}
java: {...}
dotnet: {...}
NEW_LANG: {...}  # ADD THIS
{{- end }}
```

### 2. Consistent Behavior

All languages use the same merge logic:
```yaml
{{- $merged := include "k8s-app.mergeProbe" (dict 
  "defaultsTemplate" "k8s-app.livenessProbeDefaults" 
  "user" .Values.lifecycle.livenessProbe 
  "language" .Values.appSpec.language) | fromYaml }}
```

### 3. Easy to Override

Users can override any default:
```yaml
appSpec:
  language: "golang"
lifecycle:
  livenessProbe:
    path: "/custom/health"  # Override just the path
    # Other settings use golang defaults
```

### 4. Automatic Fallback

If language not found, falls back to Python:
```yaml
{{- $languagePlans := index $allPlans $language | default (index $allPlans "python") }}
```

## Comparison with Timoni

### Timoni CUE Approach

```cue
#livenessProbesDefaults: {
  python: {path: "/health", port: 8080, ...}
  java: {path: "/actuator/health/liveness", port: 8080, ...}
  dotnet: {path: "/health/live", port: 8080, ...}
}

let _liveness = #ProbesMerge & {
  _userProbe: _config.lifecycle.livenessProbe
  _def: #livenessProbesDefaults[_config.appSpec.language]
}
livenessProbe: _liveness.result
```

### Helm Equivalent

```yaml
{{- define "k8s-app.livenessProbeDefaults" -}}
python:
  path: /health
  port: 8080
java:
  path: /actuator/health/liveness
  port: 8080
dotnet:
  path: /health/live
  port: 8080
{{- end }}

{{- $merged := include "k8s-app.mergeProbe" (dict 
  "defaultsTemplate" "k8s-app.livenessProbeDefaults" 
  "user" .Values.lifecycle.livenessProbe 
  "language" .Values.appSpec.language) | fromYaml }}
```

Both approaches:
- ✅ Use map-based lookups
- ✅ Merge user values with defaults
- ✅ Support dynamic language selection
- ✅ Easy to extend with new languages

## Testing New Languages

### 1. Lint Check

```bash
helm lint /home/ukatru/src/github/k8s-app
```

### 2. Template Rendering

```bash
helm template test /home/ukatru/src/github/k8s-app \
  --values test-values.yaml \
  --show-only templates/deployment.yaml
```

### 3. Verify Probes

```bash
helm template test /home/ukatru/src/github/k8s-app \
  --values test-values.yaml \
  --show-only templates/deployment.yaml | \
  grep -A 10 "livenessProbe:"
```

### 4. Verify Resources

```bash
helm template test /home/ukatru/src/github/k8s-app \
  --values test-values.yaml \
  --show-only templates/deployment.yaml | \
  grep -A 6 "resources:"
```

## Summary

Adding a new language requires only:

1. **Add 3 probe entries** in `_probe-defaults.tpl`
2. **Add 1 resource plan entry** in `_plan-defaults.tpl`
3. **Optional: Add env vars** in `_helpers.tpl`
4. **Update documentation**

No logic changes needed! The dynamic lookup handles everything automatically, just like Timoni's CUE approach. 🚀
