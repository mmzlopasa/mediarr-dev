/// Days, as the person sees them on their phone.
///
/// The server takes a day as YYYY-MM-DD. The generated client turns a [DateTime] into UTC first,
/// so a local midnight east of Greenwich would become the day before; these keep the day as it is.
library;

/// The day as YYYY-MM-DD, for a query.
String dayString(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// The same day at midnight UTC, so turning it into UTC changes nothing.
DateTime dayOnly(DateTime day) => DateTime.utc(day.year, day.month, day.day);
