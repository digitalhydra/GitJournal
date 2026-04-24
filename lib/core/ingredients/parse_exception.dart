/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

/// Exception thrown when ingredient parsing fails
class ParseException implements Exception {
  final String input;
  final String reason;

  const ParseException(this.input, this.reason);

  @override
  String toString() => 'ParseException: "$input" - $reason';
}
