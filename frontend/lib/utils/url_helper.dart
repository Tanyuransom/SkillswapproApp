import '../services/api_service.dart';

class UrlHelper {
  /// Fixes URLs that might have been saved with an old local IP address
  /// to ensure they work on the current network environment.
  static String fixIp(String url) {
    if (url.isEmpty) return url;
    
    // Handle relative uploads paths from backend
    if (url.startsWith('/uploads')) {
      if (url.startsWith('/uploads/shorts')) {
        return 'http://${ApiService.hostIp}:3002$url';
      } else {
        // Avatars and other auth-service uploads
        return 'http://${ApiService.hostIp}:3001$url';
      }
    }

    // Check for common local IP patterns or the specific previous one
    if (url.contains('192.168.1.')) {
      // Extract the original IP (everything between http:// and the next : or /)
      final parts = url.split('/');
      if (parts.length > 2) {
        final hostPart = parts[2]; // e.g., "192.168.1.154:3001"
        final ipOnly = hostPart.split(':')[0];
        
        if (ipOnly != ApiService.hostIp) {
          return url.replaceFirst(ipOnly, ApiService.hostIp);
        }
      }
    }
    return url;
  }
}
