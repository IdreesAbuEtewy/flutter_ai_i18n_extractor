/// Rate limiter to control API request frequency
class RateLimiter {
  final int maxRequestsPerMinute;
  final List<DateTime> _requestTimes = [];
  
  RateLimiter({required this.maxRequestsPerMinute});
  
  /// Waits if necessary to respect rate limits
  Future<void> waitIfNeeded() async {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
    
    // Remove requests older than 1 minute
    _requestTimes.removeWhere((time) => time.isBefore(oneMinuteAgo));
    
    // Check if we need to wait
    if (_requestTimes.length >= maxRequestsPerMinute) {
      final oldestRequest = _requestTimes.first;
      final waitTime = oldestRequest.add(const Duration(minutes: 1)).difference(now);
      
      if (waitTime.inMilliseconds > 0) {
        print('Rate limit reached. Waiting ${waitTime.inSeconds} seconds...');
        await Future.delayed(waitTime);
      }
    }
    
    // Record this request
    _requestTimes.add(now);
  }
  
  /// Gets the current request count in the last minute
  int get currentRequestCount {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
    
    _requestTimes.removeWhere((time) => time.isBefore(oneMinuteAgo));
    return _requestTimes.length;
  }
  
  /// Gets the time until the next request can be made
  Duration get timeUntilNextRequest {
    if (_requestTimes.length < maxRequestsPerMinute) {
      return Duration.zero;
    }
    
    final now = DateTime.now();
    final oldestRequest = _requestTimes.first;
    final nextAvailableTime = oldestRequest.add(const Duration(minutes: 1));
    
    return nextAvailableTime.isAfter(now) 
        ? nextAvailableTime.difference(now) 
        : Duration.zero;
  }
  
  /// Resets the rate limiter
  void reset() {
    _requestTimes.clear();
  }
}