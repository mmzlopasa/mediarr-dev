import SwiftUI
import WidgetKit

/// One picture from the chosen album, or what to do when there is none yet.
struct AlbumEntry: TimelineEntry {
  let date: Date
  let picture: UIImage?
  let title: String
  let note: String?
}

/// Fetches a few pictures of the chosen album and keeps them, so the widget also shows them without a
/// connection. It reads with the app's read-only key.
enum AlbumPictures {
  static let kept = 6
  static let candidates = 300

  static var folder: URL {
    let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    let url = base.appendingPathComponent("widget", isDirectory: true)
    try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
  }

  private static func get(_ share: WidgetShare, _ path: String) async throws -> Data {
    guard let url = URL(string: share.server + path) else { throw URLError(.badURL) }
    var request = URLRequest(url: url, timeoutInterval: 20)
    request.setValue(share.key, forHTTPHeaderField: "X-Api-Key")
    let (data, response) = try await URLSession.shared.data(for: request)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
    return data
  }

  /// Picture ids of the album, newest months first, as many as are worth choosing from.
  private static func ids(_ share: WidgetShare) async throws -> [String] {
    struct Buckets: Decodable { struct Bucket: Decodable { let month: String }; let buckets: [Bucket] }
    struct Month: Decodable { struct Item: Decodable { let id: String; let kind: String }; let items: [Item] }
    let months = try JSONDecoder().decode(Buckets.self, from: try await get(share, "/api/albums/\(share.albumId)/buckets"))
    var out: [String] = []
    for bucket in months.buckets where out.count < candidates {
      let month = try JSONDecoder().decode(
        Month.self, from: try await get(share, "/api/albums/\(share.albumId)/buckets/\(bucket.month)"))
      out += month.items.filter { $0.kind == "photo" }.map(\.id)
    }
    return out
  }

  /// New pictures when the connection allows, else the ones kept last time.
  static func refresh(_ share: WidgetShare) async -> [UIImage] {
    if let chosen = try? await ids(share).shuffled().prefix(kept), !chosen.isEmpty {
      var fresh: [URL] = []
      for id in chosen {
        let file = folder.appendingPathComponent("\(id).jpg")
        if !FileManager.default.fileExists(atPath: file.path),
          let data = try? await get(share, "/api/assets/\(id)/thumbnail?size=large"),
          let image = UIImage(data: data),
          let jpeg = small(image).jpegData(compressionQuality: 0.85)
        {
          try? jpeg.write(to: file)
        }
        if FileManager.default.fileExists(atPath: file.path) { fresh.append(file) }
      }
      if !fresh.isEmpty {
        let keep = Set(fresh.map(\.lastPathComponent))
        for old in (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        where !keep.contains(old.lastPathComponent) {
          try? FileManager.default.removeItem(at: old)
        }
      }
    }
    let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
    return files.compactMap { UIImage(contentsOfFile: $0.path) }
  }

  /// Small enough for a widget, which has little memory to draw with.
  private static func small(_ image: UIImage) -> UIImage {
    let side: CGFloat = 800
    let scale = min(1, side / max(image.size.width, image.size.height))
    guard scale < 1 else { return image }
    let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
    return UIGraphicsImageRenderer(size: size).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
  }
}

struct AlbumProvider: TimelineProvider {
  func placeholder(in context: Context) -> AlbumEntry {
    AlbumEntry(date: Date(), picture: nil, title: "Mediarr", note: nil)
  }

  func getSnapshot(in context: Context, completion: @escaping (AlbumEntry) -> Void) {
    completion(placeholder(in: context))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<AlbumEntry>) -> Void) {
    guard let share = WidgetShare.load() else {
      let entry = AlbumEntry(
        date: Date(), picture: nil, title: "",
        note: "Choose an album in Mediarr: Settings, Home screen widget"
          + "\n\nWidget keychain: \(WidgetShare.defaultGroup ?? "none") (\(WidgetShare.lastStatus))")
      // Looks again in a minute too, in case the app's word to reload never comes; iOS may wait longer.
      completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60))))
      return
    }
    Task {
      let pictures = await AlbumPictures.refresh(share)
      let now = Date()
      guard !pictures.isEmpty else {
        let entry = AlbumEntry(date: now, picture: nil, title: share.albumTitle, note: "No photos to show yet")
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
        Image(uiImage: picture).resizable().scaledToFill()
        if !entry.title.isEmpty {
          Text(entry.title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom))
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
    .configurationDisplayName("Mediarr album")
    .description("A photo from an album you choose in Mediarr, a different one every hour.")
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
