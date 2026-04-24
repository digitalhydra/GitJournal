/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

/// Rate limiter for web requests to avoid being banned
/// Enforces minimum delay between requests to same domain
class RateLimiter {
  static final Map<String, DateTime> _lastRequest = {};
  static const Duration _defaultDelay = Duration(seconds: 2);

  /// Waits if necessary to respect rate limit for domain
  /// 
  /// [domain] - Domain being requested (e.g., "tiktok.com")
  /// [delay] - Minimum time between requests (default: 2 seconds)
  static Future<void> wait(
    String domain, {
    Duration delay = _defaultDelay,
  }) async {
    final normalizedDomain = _normalizeDomain(domain);
    final lastRequest = _lastRequest[normalizedDomain];

    if (lastRequest != null) {
      final elapsed = DateTime.now().difference(lastRequest);
      if (elapsed < delay) {
        final waitTime = delay - elapsed;
        await Future.delayed(waitTime);
      }
    }

    _lastRequest[normalizedDomain] = DateTime.now();
  }

  /// Extracts domain from URL
  static String extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (_) {
      // If not a valid URL, return as-is
      return url;
    }
  }

  /// Normalizes domain for consistent lookup
  static String _normalizeDomain(String domain) {
    return domain.toLowerCase().replaceAll(RegExp(r'^www\.'), '');
  }

  /// Clears all rate limit history (for testing)
  static void clear() {
    _lastRequest.clear();
  }

  /// Gets time since last request to domain
  static Duration? timeSinceLastRequest(String domain) {
    final normalizedDomain = _normalizeDomain(domain);
    final lastRequest = _lastRequest[normalizedDomain];
    
    if (lastRequest == null) return null;
    return DateTime.now().difference(lastRequest);
  }

  /// Checks if domain is currently rate limited
  static bool isRateLimited(
    String domain, {
    Duration delay = _defaultDelay,
  }) {
    final elapsed = timeSinceLastRequest(domain);
    if (elapsed == null) return false;
    return elapsed < delay;
  }
}
