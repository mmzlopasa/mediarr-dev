import '../l10n/l10n.dart';

/// A browser's user agent in words a person knows, as on the web (lib/organize/agent.ts).
class Agent {
  const Agent(this.program, this.system, this.phone);

  final String program;
  final String system;
  final bool phone;

  /// "Chrome on Windows", or what can be told of it.
  String get title {
    if (program.isNotEmpty && system.isNotEmpty) {
      return l.agentProgramOnSystem(program, system);
    }
    if (program.isNotEmpty) return program;
    if (system.isNotEmpty) return system;
    return l.agentUnknownDevice;
  }
}

List<(String, String)> get _programs => [
  ('HeadlessChrome', 'Headless Chrome'),
  ('Edg/', 'Edge'),
  ('OPR/', 'Opera'),
  ('SamsungBrowser', 'Samsung Internet'),
  ('Firefox/', 'Firefox'),
  ('Chrome/', 'Chrome'),
  ('CriOS', 'Chrome'),
  ('Dart/', l.agentMediarrApp),
  ('curl/', 'curl'),
];

const _systems = [
  ('iPhone', 'iPhone'),
  ('iPad', 'iPad'),
  ('Android', 'Android'),
  ('Windows', 'Windows'),
  ('Macintosh', 'macOS'),
  ('Mac OS X', 'macOS'),
  ('CrOS', 'ChromeOS'),
  ('Linux', 'Linux'),
  ('X11', 'Linux'),
];

Agent describeAgent(String userAgent) {
  var program = '';
  for (final (mark, name) in _programs) {
    if (userAgent.contains(mark)) {
      program = name;
      break;
    }
  }
  if (program.isEmpty &&
      RegExp(r'Version/[\d.]+.*Safari').hasMatch(userAgent)) {
    program = 'Safari';
  }
  var system = '';
  for (final (mark, name) in _systems) {
    if (userAgent.contains(mark)) {
      system = name;
      break;
    }
  }
  final phone = RegExp(r'iPhone|Android.*Mobile|Mobile Safari|^Dart/')
      .hasMatch(userAgent);
  return Agent(program, system, phone);
}

/// How long ago, in plain words: "3 hours ago".
String since(DateTime at, [DateTime? now]) {
  final gap = (now ?? DateTime.now()).difference(at);
  if (gap.inSeconds < 60) return l.agentNow;
  if (gap.inMinutes < 60) return l.agentMinutesAgo(gap.inMinutes);
  if (gap.inHours < 24) return l.agentHoursAgo(gap.inHours);
  if (gap.inDays < 7) return l.agentDaysAgo(gap.inDays);
  if (gap.inDays < 30) return l.agentWeeksAgo(gap.inDays ~/ 7);
  if (gap.inDays < 365) return l.agentMonthsAgo(gap.inDays ~/ 30);
  return l.agentYearsAgo(gap.inDays ~/ 365);
}
