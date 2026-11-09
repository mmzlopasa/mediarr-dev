/// What going through a shoot needs to work out, apart from the screen.
const compareMax = 4;
const swipeDistance = 80.0;

/// A photo's verdict: 1 picked, -1 rejected, 0 none.
class CullMark {
  CullMark({required this.pick, required this.rating});

  int pick;
  int rating;
}

/// The photos to have ready: three ahead and one behind, the nearest first.
List<int> preloadIndexes(
  int index,
  int length, {
  int ahead = 3,
  int behind = 1,
}) => [
  for (var step = 1; step <= ahead; step++)
    if (index + step < length) index + step,
  for (var step = 1; step <= behind; step++)
    if (index - step >= 0) index - step,
];

/// A list cut in the pieces one request can take.
List<List<T>> chunksOf<T>(List<T> list, [int size = 1000]) => [
  for (var at = 0; at < list.length; at += size)
    list.sublist(at, at + size < list.length ? at + size : list.length),
];

/// The photos compared after this one is added or taken out; a full list takes no more.
List<String> toggleCompared(List<String> compared, String id) {
  if (compared.contains(id)) return [...compared]..remove(id);
  return compared.length >= compareMax ? compared : [...compared, id];
}

/// What a finger's drag means: up picks, down rejects; a sideways one is not a verdict.
int? swipeVerdict(double dx, double dy) {
  if (dy.abs() < swipeDistance || dy.abs() <= dx.abs() * 1.5) return null;
  return dy < 0 ? 1 : -1;
}

/// Which way a sideways drag moves through the photos, if it is one.
int? swipeMove(double dx, double dy) {
  if (dx.abs() < swipeDistance || dx.abs() <= dy.abs() * 1.5) return null;
  return dx > 0 ? -1 : 1;
}
