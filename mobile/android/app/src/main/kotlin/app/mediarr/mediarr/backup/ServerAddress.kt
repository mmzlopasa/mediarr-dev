package app.mediarr.mediarr.backup

import java.net.URI
import java.net.URISyntaxException

/**
 * A server address the app may send its key to: http or https, a host, and nothing after the path.
 * http stays allowed, as the server is often reached at http://its-ip:9851 at home.
 */
fun isServerAddress(value: String?): Boolean {
    if (value.isNullOrBlank() || value.length > 2048) return false
    return try {
        val uri = URI(value)
        (uri.scheme == "http" || uri.scheme == "https") &&
            !uri.host.isNullOrEmpty() &&
            uri.rawUserInfo == null &&
            uri.rawQuery == null &&
            uri.rawFragment == null
    } catch (_: URISyntaxException) {
        false
    }
}
