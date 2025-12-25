import SwiftUI

extension Image {
    /// Initialize an Image from an asset name with tolerant fallbacks:
    /// 1. Try the name as-is
    /// 2. Try capitalizing the first character (e.g. "icon_mood" -> "Icon_mood")
    /// 3. Try lowercased and uppercased variants
    /// 4. Fallback to a system symbol (questionmark)
    init(assetOrFallback name: String) {
        // Try as-is
        if UIImage(named: name) != nil {
            self.init(name)
            return
        }

        // Try capitalizing first letter (common mismatch)
        if name.count > 0 {
            let alt = name.prefix(1).uppercased() + name.dropFirst()
            if UIImage(named: String(alt)) != nil {
                self.init(String(alt))
                return
            }
        }

        // Try other reasonable variants
        let lower = name.lowercased()
        if UIImage(named: lower) != nil {
            self.init(lower)
            return
        }
        let upper = name.uppercased()
        if UIImage(named: upper) != nil {
            self.init(upper)
            return
        }

        // Last resort: try developer-generated asset symbol names without prefix (e.g. remove "icon_")
        if lower.hasPrefix("icon_") {
            let stripped = String(lower.dropFirst("icon_".count))
            if UIImage(named: stripped) != nil {
                self.init(stripped)
                return
            }
            let strippedCapital = stripped.prefix(1).uppercased() + stripped.dropFirst()
            if UIImage(named: String(strippedCapital)) != nil {
                self.init(String(strippedCapital))
                return
            }
        }

        // Log for debugging so we can see missing assets at runtime
        #if DEBUG
        print("⚠️ No image named '\(name)' found in asset catalog; using fallback symbol")
        #endif

        // Fallback to SF Symbol
        self.init(systemName: "questionmark.circle")
    }
}
