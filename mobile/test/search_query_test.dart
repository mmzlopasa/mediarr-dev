import 'package:flutter_test/flutter_test.dart';
import 'package:mediarr/services/search_query.dart';
import 'package:mediarr_api/api.dart';

String day(DateTime value) => '${value.year}-${value.month}-${value.day}';

void main() {
  test('a search needs words or a filter', () {
    expect(const SearchQuery().isEmpty, isTrue);
    expect(const SearchQuery(words: '  ').isEmpty, isTrue);
    expect(const SearchQuery(type: 'video').isEmpty, isFalse);
    expect(const SearchQuery(favorite: true, tags: ['summer']).chosen, 2);
  });

  test('chips tell what was found in the words from what was chosen', () {
    final filters = SearchFilters(
      people: [PersonRef(id: 'p1', name: 'Ana')],
      place: 'Hvar',
      camera: 'X-T5',
      from: DateTime(2024),
      to: DateTime(2024, 12, 31),
    );
    const query = SearchQuery(words: 'Ana Hvar 2024', camera: 'X-T5');
    final chips = chipsFor(filters, query, day);
    expect(
      [for (final chip in chips) (chip.label, chip.found)],
      [
        ('2024-1-1 – 2024-12-31', true),
        ('Ana', true),
        ('Hvar', true),
        ('X-T5', false),
      ],
    );
  });

  test('a found filter goes away by searching the words as they are', () {
    final filters = SearchFilters(
      people: [PersonRef(id: 'p1', name: 'Ana')],
      place: 'Hvar',
      from: DateTime(2024),
      to: DateTime(2024, 12, 31),
    );
    const query = SearchQuery(words: 'Ana Hvar 2024');
    final hvar = chipsFor(
      filters,
      query,
      day,
    ).firstWhere((chip) => chip.key == 'place');
    final next = withoutChip(query, hvar, filters);
    expect(next.plain, isTrue);
    expect(next.place, isNull);
    expect(next.people, ['p1']);
    expect(next.from, '2024-01-01');
    expect(next.to, '2024-12-31');
  });

  test('a chosen filter simply goes away', () {
    final filters = SearchFilters(tags: ['summer', 'family'], favorite: true);
    const query = SearchQuery(tags: ['summer', 'family'], favorite: true);
    final chips = chipsFor(filters, query, day);
    final summer = chips.firstWhere((chip) => chip.value == 'summer');
    expect(withoutChip(query, summer, filters).tags, ['family']);
    final favourite = chips.firstWhere((chip) => chip.key == 'favorite');
    expect(withoutChip(query, favourite, filters).favorite, isFalse);
  });
}
