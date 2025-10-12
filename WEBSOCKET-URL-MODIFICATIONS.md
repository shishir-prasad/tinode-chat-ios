# WebSocket URL Modifications Guide

**QixSecure BCP - Remove Port and Add API Key as Query Parameter**

---

## 🎯 **Objective**

Modify the WebSocket connection to:
1. **Remove redundant port** (`:443` for WSS, `:80` for WS)
2. **Add API key as query parameter** instead of HTTP header

**Target URL Format:**
```
wss://fochat-dev.saleswarp.com/v0/channels?apikey=AQAAAAABAAByCoXpLdVgii7-77YqZ6S4
```

---

## 🔍 **Problem Analysis**

### **Current Behavior**
```
URL: wss://fochat-dev.saleswarp.com:443/v0/channels
Header: X-Tinode-APIKey: AQAAAAABAAByCoXpLdVgii7-77YqZ6S4
```

### **Issues Identified**
1. **Redundant Port Assignment**: Code automatically adds `:443` for WSS and `:80` for WS
2. **Header-Based API Key**: API key sent as HTTP header instead of query parameter

### **Root Cause Location**
- **Port Assignment**: `TinodeSDK/Connection.swift:67-69`
- **API Key Header**: `TinodeSDK/Connection.swift:121`

---

## 🔧 **Implementation Changes**

### **File: `TinodeSDK/Connection.swift`**

#### **1. Remove Automatic Port Assignment**

**Location**: Lines 67-69

**Original Code:**
```swift
if endpointComponenets.port == nil {
    endpointComponenets.port = useTLS ? 443 : 80
}
```

**Modified Code:**
```swift
// Remove automatic port assignment - let URLComponents handle defaults
// if endpointComponenets.port == nil {
//     endpointComponenets.port = useTLS ? 443 : 80
// }
```

#### **2. Add API Key as Query Parameter**

**Location**: After line 66 (after scheme detection)

**Added Code:**
```swift
// Add API key as query parameter
var queryItems = endpointComponenets.queryItems ?? []
queryItems.append(URLQueryItem(name: "apikey", value: apiKey))
endpointComponenets.queryItems = queryItems
```

#### **3. Remove API Key from HTTP Header**

**Location**: Lines 119-123

**Original Code:**
```swift
private func createUrlRequest() throws -> URLRequest {
    var request = URLRequest(url: endpointComponenets.url!)
    request.addValue(apiKey, forHTTPHeaderField: "X-Tinode-APIKey")
    return request
}
```

**Modified Code:**
```swift
private func createUrlRequest() throws -> URLRequest {
    var request = URLRequest(url: endpointComponenets.url!)
    // API key is now in URL query parameters, no need for header
    // request.addValue(apiKey, forHTTPHeaderField: "X-Tinode-APIKey")
    return request
}
```

---

## 📝 **Complete Modified Code Sections**

### **Connection Initialization (Lines 56-80)**

```swift
init(open url: URL, with apiKey: String, notify listener: ConnectionListener?) {
    self.apiKey = apiKey
    // TODO: apply necessary URL modifications.
    self.endpointComponenets = URLComponents(url: url, resolvingAgainstBaseURL: false)!
    self.connectionListener = listener
    if let scheme = endpointComponenets.scheme, scheme == "wss" || scheme == "https" {
        endpointComponenets.scheme = "wss"
        useTLS = true
    } else {
        endpointComponenets.scheme = "ws"
    }

    // Add API key as query parameter
    var queryItems = endpointComponenets.queryItems ?? []
    queryItems.append(URLQueryItem(name: "apikey", value: apiKey))
    endpointComponenets.queryItems = queryItems

    // Remove automatic port assignment - let URLComponents handle defaults
    // if endpointComponenets.port == nil {
    //     endpointComponenets.port = useTLS ? 443 : 80
    // }

    self.webSocketConnection = WebSocket(timeout: kConnectionTimeout, delegate: self)
    maybeInitReconnectClosure()
}
```

### **URL Request Creation (Lines 127-132)**

```swift
private func createUrlRequest() throws -> URLRequest {
    var request = URLRequest(url: endpointComponenets.url!)
    // API key is now in URL query parameters, no need for header
    // request.addValue(apiKey, forHTTPHeaderField: "X-Tinode-APIKey")
    return request
}
```

---

## ✅ **Expected Results**

### **Before Modifications**
```
URL: wss://fochat-dev.saleswarp.com:443/v0/channels
Headers: X-Tinode-APIKey: AQAAAAABAAByCoXpLdVgii7-77YqZ6S4
```

### **After Modifications**
```
URL: wss://fochat-dev.saleswarp.com/v0/channels?apikey=AQAAAAABAAByCoXpLdVgii7-77YqZ6S4
Headers: (no API key header)
```

### **Protocol Matrix**
| TLS Setting | WebSocket URL |
|-------------|---------------|
| `USE_TLS = YES` | `wss://fochat-dev.saleswarp.com/v0/channels?apikey=...` |
| `USE_TLS = NO` | `ws://fochat-dev.saleswarp.com/v0/channels?apikey=...` |

---

## ⚠️ **Important Considerations**

### **1. Server Compatibility**
**Critical**: Ensure your server supports API key authentication via query parameters:

- **Server-side changes required** if currently expecting `X-Tinode-APIKey` header
- **Tinode server configuration** may need updates
- **Authentication middleware** must handle query parameter extraction

### **2. Security Implications**

#### **Query Parameter Visibility**
API keys in query parameters are visible in:
- **Server access logs**
- **Proxy server logs**
- **Network monitoring tools**
- **Browser development tools**
- **Referrer headers** (if page redirects)

#### **Header vs Query Parameter Security**
| Method | Visibility | Security Level |
|--------|------------|----------------|
| **HTTP Header** | Less visible | ✅ **Higher** |
| **Query Parameter** | More visible | ⚠️ **Lower** |

#### **Mitigation Strategies**
- Use **TLS/WSS** to encrypt transmission
- Configure server logs to **exclude query parameters**
- Implement **short-lived tokens** with expiration
- Consider **token rotation** mechanisms

### **3. URL Length Limitations**
- **WebSocket URLs** have practical length limits (~2048 characters)
- **Current API key**: 32 characters (well within limits)
- **Future tokens**: Ensure length compatibility

---

## 🧪 **Testing Checklist**

### **Pre-Deployment Testing**
- [ ] **WebSocket Connection**: Verify successful connection establishment
- [ ] **Authentication**: Confirm API key authentication works via query parameter
- [ ] **Port Behavior**: Ensure no `:443` or `:80` appears in URLs
- [ ] **TLS vs Non-TLS**: Test both `wss://` and `ws://` scenarios
- [ ] **Server Logs**: Check server correctly receives and processes API key
- [ ] **Error Handling**: Test invalid API key scenarios

### **Integration Testing**
- [ ] **SSO Login**: Verify SSO functionality works with new URL format
- [ ] **Auto-reconnection**: Test reconnection behavior with query parameters
- [ ] **Different Networks**: Test on various network configurations
- [ ] **Production Environment**: Validate against production server

### **Security Testing**
- [ ] **Traffic Analysis**: Verify TLS encryption of API key
- [ ] **Log Analysis**: Ensure API keys are properly protected in logs
- [ ] **Man-in-the-middle**: Confirm encrypted transmission
- [ ] **Token Exposure**: Check for unintended API key leakage

---

## 🚀 **Deployment Steps**

### **Phase 1: Code Deployment**
1. **Apply code changes** to `TinodeSDK/Connection.swift`
2. **Test locally** with development environment
3. **Validate URL format** matches expected pattern
4. **Verify functionality** with test WebSocket server

### **Phase 2: Server Configuration**
1. **Update server** to accept API key query parameters
2. **Maintain backward compatibility** (support both methods temporarily)
3. **Configure logging** to protect API key exposure
4. **Test authentication flow** end-to-end

### **Phase 3: Production Rollout**
1. **Deploy to staging** environment first
2. **Run comprehensive tests** including load testing
3. **Monitor for errors** and connection issues
4. **Gradual rollout** to production
5. **Remove header-based authentication** after validation

---

## 🔄 **Rollback Plan**

If issues arise, revert changes by:

### **Immediate Rollback**
```swift
// Restore automatic port assignment
if endpointComponenets.port == nil {
    endpointComponenets.port = useTLS ? 443 : 80
}

// Restore header-based API key
request.addValue(apiKey, forHTTPHeaderField: "X-Tinode-APIKey")

// Remove query parameter addition
// (comment out the queryItems code)
```

### **Server-Side Rollback**
- **Re-enable** `X-Tinode-APIKey` header processing
- **Disable** query parameter authentication
- **Verify** original functionality restored

---

## 📊 **Monitoring & Metrics**

### **Key Metrics to Monitor**
- **Connection Success Rate**: Should remain 100%
- **Authentication Failures**: Should not increase
- **WebSocket Errors**: Monitor for new error patterns
- **Server Response Times**: Ensure no performance degradation
- **API Key Security**: Monitor for exposure in logs

### **Alerting Thresholds**
- **Connection failures** > 1%
- **Authentication errors** > 0.5%
- **Response time degradation** > 20%
- **Security incidents**: Any API key exposure

---

## 📚 **Related Documentation**

- **SSO Implementation Guide**: `SSO-IMPLEMENTATION-GUIDE.md`
- **Project Index**: `PROJECT-INDEX.md`
- **WebSocket RFC**: [RFC 6455](https://tools.ietf.org/html/rfc6455)
- **URL Query Parameters**: [RFC 3986](https://tools.ietf.org/html/rfc3986)

---

*Generated by Claude Code SuperClaude Framework*
*Project: QixSecure BCP - WebSocket URL Modifications*
*Last Updated: Implementation completed with code changes applied*