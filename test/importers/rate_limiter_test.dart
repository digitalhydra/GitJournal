/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:gitjournal/importers/rate_limiter.dart';

void main() {
  group('RateLimiter', () {
    setUp(() {
      RateLimiter.clear();
    });

    test('allows first request immediately', () async {
      final stopwatch = Stopwatch()..start();
      await RateLimiter.wait('example.com', delay: Duration(milliseconds: 100));
      stopwatch.stop();
      
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('waits between requests to same domain', () async {
      await RateLimiter.wait('example.com', delay: Duration(milliseconds: 100));
      
      final stopwatch = Stopwatch()..start();
      await RateLimiter.wait('example.com', delay: Duration(milliseconds: 100));
      stopwatch.stop();
      
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(90));
    });

    test('different domains dont block each other', () async {
      await RateLimiter.wait('example.com', delay: Duration(milliseconds: 500));
      
      final stopwatch = Stopwatch()..start();
      await RateLimiter.wait('other.com', delay: Duration(milliseconds: 100));
      stopwatch.stop();
      
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('extracts domain from URL', () {
      expect(RateLimiter.extractDomain('https://example.com/recipe'), equals('example.com'));
      expect(RateLimiter.extractDomain('http://www.example.com/path'), equals('www.example.com'));
      expect(RateLimiter.extractDomain('https://sub.example.com:8080/test'), equals('sub.example.com'));
    });

    test('extracts domain from plain string returns empty if not valid URI', () {
      expect(RateLimiter.extractDomain('example.com'), equals(''));
    });

    test('checks if rate limited', () async {
      expect(RateLimiter.isRateLimited('example.com'), isFalse);
      
      await RateLimiter.wait('example.com', delay: Duration(milliseconds: 200));
      
      expect(RateLimiter.isRateLimited('example.com', delay: Duration(milliseconds: 200)), isTrue);
      
      // Wait for rate limit to expire
      await Future.delayed(Duration(milliseconds: 250));
      expect(RateLimiter.isRateLimited('example.com', delay: Duration(milliseconds: 200)), isFalse);
    });

    test('returns time since last request', () async {
      expect(RateLimiter.timeSinceLastRequest('example.com'), isNull);
      
      await RateLimiter.wait('example.com');
      
      final elapsed = RateLimiter.timeSinceLastRequest('example.com');
      expect(elapsed, isNotNull);
      expect(elapsed!.inMilliseconds, greaterThanOrEqualTo(0));
    });

    test('normalizes domain names', () async {
      await RateLimiter.wait('Example.COM');
      
      // Should be same domain
      expect(RateLimiter.isRateLimited('example.com'), isTrue);
    });

    test('removes www prefix', () async {
      await RateLimiter.wait('www.example.com');
      
      // Should be same domain
      expect(RateLimiter.isRateLimited('example.com'), isTrue);
    });
  });
}
