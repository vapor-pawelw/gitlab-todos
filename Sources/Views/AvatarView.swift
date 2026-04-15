import SwiftUI

private struct AvatarCacheKey: EnvironmentKey {
    static let defaultValue: AvatarCache? = nil
}

extension EnvironmentValues {
    var avatarCache: AvatarCache? {
        get { self[AvatarCacheKey.self] }
        set { self[AvatarCacheKey.self] = newValue }
    }
}

struct AvatarView: View {
    let url: URL?
    var size: CGFloat = 32

    @Environment(\.avatarCache) private var cache
    @State private var image: NSImage?

    var body: some View {
        ZStack {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .task(id: url) {
            guard let url, let cache else {
                image = nil
                return
            }
            image = await cache.image(for: url)
        }
    }
}
