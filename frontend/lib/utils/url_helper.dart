import '../services/api_service.dart';

class UrlHelper {
  /// Fixes URLs that might have been saved with an old local IP address
  /// to ensure they work on the current network environment.
  static String fixIp(String url) {
    if (url.isEmpty) return url;
    
    // Handle relative uploads paths from backend
    if (url.startsWith('/uploads')) {
      if (url.startsWith('/uploads/shorts')) {
        // Route through Gateway for better mobile compatibility
        return 'http://${ApiService.hostIp}:3000/api/shorts$url';
      } else if (url.startsWith('/uploads/courses')) {
        return 'http://${ApiService.hostIp}:3000/api/courses$url';
      } else {
        // Avatars and other user-service uploads
        return 'http://${ApiService.hostIp}:3000/api/users$url';
      }
    }

    // Check for absolute URLs with old IPs or localhost
    if (url.startsWith('http://')) {
      final uri = Uri.parse(url);
      final host = uri.host;
      
      // If host is an IP or localhost and not the current hostIp
      if (host != ApiService.hostIp) {
        // Only replace if it looks like a local environment IP (starts with 192, 10, or is localhost)
        if (host == 'localhost' || host == '127.0.0.1' || host.startsWith('192.168.') || host.startsWith('10.')) {
          return url.replaceFirst(host, ApiService.hostIp);
        }
      }
    }
    
    return url;
  }
}
