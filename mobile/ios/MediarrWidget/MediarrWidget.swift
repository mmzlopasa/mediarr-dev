import SwiftUI
import WidgetKit

/// One picture from the chosen album, or what to do when there is none yet.
struct AlbumEntry: TimelineEntry {
  let date: Date
  let picture: UIImage?
  let title: String
  let note: String?
}

/// The widget's few words, in the phone's language. A table here rather than string files, so no
/// change to the Xcode project is needed; the app's own texts live in its .arb files.
struct WidgetText {
  let chooseAlbum: String
  let noPhotos: String
  let name: String
  let description: String

  static let all: [String: WidgetText] = [
    "en": WidgetText(
      chooseAlbum: "Choose an album in Mediarr: Settings, Home screen widget",
      noPhotos: "No photos to show yet",
      name: "Mediarr album",
      description: "A photo from an album you choose in Mediarr, a different one every hour."),
    "hr": WidgetText(
      chooseAlbum: "Odaberi album u Mediarru: Postavke, Widget na početnom zaslonu",
      noPhotos: "Još nema fotografija za prikaz",
      name: "Mediarr album",
      description: "Fotografija iz albuma koji odabereš u Mediarru, svakog sata druga."),
    "de": WidgetText(
      chooseAlbum: "Wähle ein Album in Mediarr: Einstellungen, Widget für den Startbildschirm",
      noPhotos: "Noch keine Fotos zum Anzeigen",
      name: "Mediarr-Album",
      description: "Ein Foto aus einem Album, das du in Mediarr wählst, jede Stunde ein anderes."),
    "sl": WidgetText(
      chooseAlbum: "Izberi album v Mediarru: Nastavitve, Pripomoček za začetni zaslon",
      noPhotos: "Še ni fotografij za prikaz",
      name: "Album Mediarr",
      description: "Fotografija iz albuma, ki ga izbereš v Mediarru, vsako uro druga."),
  ]

  /// The first of the phone's languages the widget speaks, else English.
  static var current: WidgetText {
    for code in Locale.preferredLanguages {
      let language = String(code.split(separator: "-").first ?? "")
      if let text = all[language] { return text }
    }
    return all["en"]!
  }
}

/// Fetches a few pictures of the chosen album and keeps them, so the widget also shows them without a
/// connection. It reads with the app's read-only key.
enum AlbumPictures {
  static let kept = 6
  /// Enough to choose from without walking a large album month by month.
  static let candidates = 120
  static let months = 4
  /// iOS stops an extension that takes long, which leaves the widget blank: everything the
  /// timeline fetches has to fit in this, and what is kept by then is shown.
  static let deadline: TimeInterval = 15
  /// The smallest preview the server makes that still fills a large widget ("small" is 500 px).
  static let size = "large"

  static var folder: URL {
    let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    let url = base.appendingPathComponent("widget-pictures", isDirectory: true)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
  }

  private static func get(_ share: WidgetShare, _ path: String) async throws -> Data {
    guard let url = URL(string: share.server + path) else { throw URLError(.badURL) }
    var request = URLRequest(url: url, timeoutInterval: 8)
    request.setValue(share.key, forHTTPHeaderField: "X-Api-Key")
    let (data, response) = try await URLSession.shared.data(for: request)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
    return data
  }

  /// Picture ids of the album's newest months, as many as are worth choosing from.
  private static func ids(_ share: WidgetShare) async throws -> [String] {
    struct Buckets: Decodable { struct Bucket: Decodable { let month: String }; let buckets: [Bucket] }
    struct Month: Decodable { struct Item: Decodable { let id: String; let kind: String }; let items: [Item] }
    let all = try JSONDecoder().decode(Buckets.self, from: try await get(share, "/api/albums/\(share.albumId)/buckets"))
    var out: [String] = []
    for bucket in all.buckets.prefix(months) where out.count < candidates {
      try Task.checkCancellation()
      let month = try JSONDecoder().decode(
        Month.self, from: try await get(share, "/api/albums/\(share.albumId)/buckets/\(bucket.month)"))
      out += month.items.filter { $0.kind == "photo" }.map(\.id)
    }
    return out
  }

  /// Downloads new pictures one by one, so each one that arrives is kept even if time runs out.
  private static func fetch(_ share: WidgetShare) async {
    guard let chosen = try? await ids(share).shuffled().prefix(kept), !chosen.isEmpty else { return }
    for id in chosen {
      if Task.isCancelled { return }
      let file = folder.appendingPathComponent("\(id).jpg")
      if FileManager.default.fileExists(atPath: file.path) {
        // Chosen again: it counts as new, so the clean-up keeps it.
        try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: file.path)
        continue
      }
      if let data = try? await get(share, "/api/assets/\(id)/thumbnail?size=\(size)"),
        let image = UIImage(data: data),
        let jpeg = small(image).jpegData(compressionQuality: 0.85)
      {
        try? jpeg.write(to: file)
      }
    }
  }

  /// New pictures when the connection allows within the deadline, and the ones kept before for
  /// whatever did not arrive in time.
  static func refresh(_ share: WidgetShare) async -> [UIImage] {
    await withTaskGroup(of: Void.self) { group in
      group.addTask { await AlbumPictures.fetch(share) }
      group.addTask { _ = try? await Task.sleep(nanoseconds: UInt64(AlbumPictures.deadline * 1_000_000_000)) }
      // Whichever ends first ends the other: the work when it is done, or the clock.
      _ = await group.next()
      group.cancelAll()
    }
    tidy()
    return keptPictures()
  }

  /// The newest files, newest first.
  private static func files() -> [URL] {
    let urls =
      (try? FileManager.default.contentsOfDirectory(
        at: folder, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
    func date(_ url: URL) -> Date {
      (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
    }
    return urls.sorted { date($0) > date($1) }
  }

  /// Keeps only as many pictures as the widget shows, the newest ones.
  private static func tidy() {
    for old in files().dropFirst(kept) {
      try? FileManager.default.removeItem(at: old)
    }
  }

  /// What is on the phone already, without asking the server.
  static func keptPictures(limit: Int = AlbumPictures.kept) -> [UIImage] {
    files().prefix(limit).compactMap { UIImage(contentsOfFile: $0.path) }.map(small)
  }

  /// Small enough for a widget: iOS leaves a widget blank when its picture has more pixels than it
  /// shows. The side is in pixels, so the screen's scale must not multiply it.
  static let side: CGFloat = 700

  private static func small(_ image: UIImage) -> UIImage {
    let pixels = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
    let scale = min(1, side / max(pixels.width, pixels.height))
    let size = CGSize(width: (pixels.width * scale).rounded(), height: (pixels.height * scale).rounded())
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    return UIGraphicsImageRenderer(size: size, format: format).image { _ in
      image.draw(in: CGRect(origin: .zero, size: size))
    }
  }
}

struct AlbumProvider: TimelineProvider {
  func placeholder(in context: Context) -> AlbumEntry {
    AlbumEntry(date: Date(), picture: nil, title: "Mediarr", note: nil)
  }

  /// For the widget gallery and before the first timeline: a kept picture, else what to do.
  func getSnapshot(in context: Context, completion: @escaping (AlbumEntry) -> Void) {
    let share = WidgetShare.load()
    if let picture = AlbumPictures.keptPictures(limit: 1).first {
      completion(AlbumEntry(date: Date(), picture: picture, title: share?.albumTitle ?? "", note: nil))
      return
    }
    let text = WidgetText.current
    completion(
      AlbumEntry(
        date: Date(), picture: nil, title: share?.albumTitle ?? "",
        note: share == nil ? text.chooseAlbum : text.noPhotos))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<AlbumEntry>) -> Void) {
    guard let share = WidgetShare.load() else {
      let entry = AlbumEntry(date: Date(), picture: nil, title: "", note: WidgetText.current.chooseAlbum)
      // Looks again in a minute too, in case the app's word to reload never comes; iOS may wait longer.
      completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60))))
      return
    }
    Task {
      let pictures = await AlbumPictures.refresh(share)
      let now = Date()
      guard !pictures.isEmpty else {
        let entry = AlbumEntry(date: now, picture: nil, title: share.albumTitle, note: WidgetText.current.noPhotos)
        completion(Timeline(entries: [entry], policy: .after(now.addingTimeInterval(3600))))
        return
      }
      // A different picture every hour, and new ones from the album after that.
      let entries = pictures.enumerated().map { index, picture in
        AlbumEntry(
          date: now.addingTimeInterval(Double(index) * 3600), picture: picture, title: share.albumTitle, note: nil)
      }
      completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(Double(pictures.count) * 3600))))
    }
  }
}

struct AlbumWidgetView: View {
  let entry: AlbumEntry

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      if let picture = entry.picture {
        photo(picture)
        if !entry.title.isEmpty {
          if #available(iOS 16.0, *) {
            AccentAwareTitle(title: entry.title)
          } else {
            AlbumTitle(title: entry.title, band: true)
          }
        }
      } else {
        Text(entry.note ?? "")
          .font(.footnote)
          .multilineTextAlignment(.center)
          .padding()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .widgetBackground()
  }
}

/// The album's name over the bottom of the photo, on a dark band so it reads on a light photo.
struct AlbumTitle: View {
  let title: String
  let band: Bool

  var body: some View {
    Text(title)
      .font(.caption.weight(.semibold))
      .foregroundStyle(.white)
      .lineLimit(1)
      .padding(10)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        LinearGradient(
          colors: [.clear, .black.opacity(band ? 0.6 : 0)], startPoint: .top, endPoint: .bottom))
  }
}

/// On a tinted or clear home screen iOS draws everything but the photo in one light colour, so the
/// dark band would become a whitish one over the photo: there the name goes without it.
@available(iOS 16.0, *)
struct AccentAwareTitle: View {
  let title: String
  @Environment(\.widgetRenderingMode) private var mode

  var body: some View {
    AlbumTitle(title: title, band: mode == .fullColor)
  }
}

/// A photo stays a photo on a tinted or clear home screen too, where iOS would otherwise draw every
/// picture of a widget as a flat shape in one colour.
@ViewBuilder
func photo(_ picture: UIImage) -> some View {
  if #available(iOS 18.0, *) {
    Image(uiImage: picture).resizable().widgetAccentedRenderingMode(.fullColor).scaledToFill()
  } else {
    Image(uiImage: picture).resizable().scaledToFill()
  }
}

extension View {
  /// iOS 17 asks a widget for its background; older ones draw it as part of the view.
  @ViewBuilder
  func widgetBackground() -> some View {
    if #available(iOS 17.0, *) {
      containerBackground(for: .widget) { Color(red: 0.96, green: 0.95, blue: 0.92) }
    } else {
      background(Color(red: 0.96, green: 0.95, blue: 0.92))
    }
  }
}

@main
struct MediarrWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "MediarrAlbum", provider: AlbumProvider()) { entry in
      AlbumWidgetView(entry: entry)
    }
    .configurationDisplayName(WidgetText.current.name)
    .description(WidgetText.current.description)
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    .contentMarginsDisabledIfAvailable()
  }
}

extension WidgetConfiguration {
  /// The picture fills the widget to its edges on iOS 17 too.
  func contentMarginsDisabledIfAvailable() -> some WidgetConfiguration {
    if #available(iOSApplicationExtension 17.0, *) {
      return contentMarginsDisabled()
    }
    return self
  }
}
