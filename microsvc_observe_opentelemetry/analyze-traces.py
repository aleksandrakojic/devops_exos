# Create trace analysis script
import requests
import json
import time
from datetime import datetime, timedelta

JAEGER_URL = "http://localhost:16686"

def get_traces(service_name=None, limit=20):
    """Fetch traces from Jaeger API"""
    params = {
        'limit': limit,
        'lookback': '1h'
    }
    if service_name:
        params['service'] = service_name
    
    response = requests.get(f"{JAEGER_URL}/api/traces", params=params)
    if response.status_code == 200:
        return response.json()
    return None

def analyze_trace_performance():
    """Analyze trace performance metrics"""
    print("🔍 Analyzing trace performance...")
    
    services = ['api-gateway', 'user-service', 'order-service', 'inventory-service']
    
    for service in services:
        traces = get_traces(service)
        if traces and 'data' in traces:
            trace_data = traces['data']
            if trace_data:
                durations = []
                for trace in trace_data:
                    if 'spans' in trace:
                        root_span = min(trace['spans'], key=lambda x: x['startTime'])
                        duration = root_span.get('duration', 0) / 1000  # Convert to ms
                        durations.append(duration)
                
                if durations:
                    avg_duration = sum(durations) / len(durations)
                    max_duration = max(durations)
                    min_duration = min(durations)
                    
                    print(f"\n📊 {service}:")
                    print(f"  Average duration: {avg_duration:.2f}ms")
                    print(f"  Max duration: {max_duration:.2f}ms")
                    print(f"  Min duration: {min_duration:.2f}ms")
                    print(f"  Total traces: {len(durations)}")

def find_slow_traces(threshold_ms=1000):
    """Find traces slower than threshold"""
    print(f"\n🐌 Finding traces slower than {threshold_ms}ms...")
    
    traces = get_traces(limit=50)
    slow_traces = []
    
    if traces and 'data' in traces:
        for trace in traces['data']:
            if 'spans' in trace:
                root_span = min(trace['spans'], key=lambda x: x['startTime'])
                duration = root_span.get('duration', 0) / 1000
                
                if duration > threshold_ms:
                    slow_traces.append({
                        'trace_id': trace['traceID'],
                        'duration': duration,
                        'operation': root_span.get('operationName', 'unknown'),
                        'service': root_span.get('process', {}).get('serviceName', 'unknown')
                    })
    
    if slow_traces:
        print(f"Found {len(slow_traces)} slow traces:")
        for trace in sorted(slow_traces, key=lambda x: x['duration'], reverse=True)[:5]:
            print(f"  🔗 Trace ID: {trace['trace_id'][:16]}...")
            print(f"     Duration: {trace['duration']:.2f}ms")
            print(f"     Operation: {trace['operation']}")
            print(f"     Service: {trace['service']}")
            print(f"     URL: {JAEGER_URL}/trace/{trace['trace_id']}")
            print()
    else:
        print("No slow traces found!")

def analyze_error_traces():
    """Find traces with errors"""
    print("\n❌ Analyzing error traces...")
    
    traces = get_traces(limit=100)
    error_traces = []
    
    if traces and 'data' in traces:
        for trace in traces['data']:
            if 'spans' in trace:
                for span in trace['spans']:
                    tags = span.get('tags', [])
                    has_error = any(tag.get('key') == 'error' and tag.get('value') == True for tag in tags)
                    
                    if has_error:
                        error_traces.append({
                            'trace_id': trace['traceID'],
                            'operation': span.get('operationName'),
                            'service': span.get('process', {}).get('serviceName')
                        })
                        break
    
    if error_traces:
        print(f"Found {len(error_traces)} traces with errors:")
        for trace in error_traces[:5]:
            print(f"  🔗 {trace['trace_id'][:16]}... - {trace['service']} - {trace['operation']}")
    else:
        print("No error traces found!")

if __name__ == "__main__":
    print("🔍 Microservices Trace Analysis")
    print("=" * 40)
    
    try:
        analyze_trace_performance()
        find_slow_traces()
        analyze_error_traces()
        
        print("\n✅ Analysis complete!")
        print(f"\n🌐 View traces in Jaeger UI: {JAEGER_URL}")
        
    except requests.exceptions.ConnectionError:
        print(f"❌ Could not connect to Jaeger at {JAEGER_URL}")
        print("Make sure Jaeger is running and accessible.")


# chmod +x analyze-traces.py

# # Run trace analysis
# python3 analyze-traces.py