import SwiftUI
import WebKit

// MARK: - Inline GIF-like autoplay player (muted, looping, no controls)

struct YouTubeInlineView: UIViewRepresentable {
    let videoID: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.javaScriptEnabled = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.isUserInteractionEnabled = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            html, body { background: #000; width: 100%; height: 100%; overflow: hidden; }
            iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: none; pointer-events: none; }
        </style>
        </head>
        <body>
        <iframe id="yt"
            src="https://www.youtube-nocookie.com/embed/\(videoID)?autoplay=1&mute=1&controls=0&playsinline=1&rel=0&modestbranding=1&showinfo=0&iv_load_policy=3&enablejsapi=1&origin=https://www.youtube-nocookie.com"
            allow="autoplay; encrypted-media">
        </iframe>
        <script>
            // Listen for YouTube postMessage events and seek to 0 on ended
            window.addEventListener('message', function(e) {
                try {
                    var data = JSON.parse(e.data);
                    // info playerState: -1=unstarted, 0=ended, 1=playing, 2=paused, 3=buffering
                    if (data.event === 'infoDelivery' && data.info && data.info.playerState === 0) {
                        var iframe = document.getElementById('yt');
                        // Seek to beginning via postMessage command
                        iframe.contentWindow.postMessage(JSON.stringify({
                            event: 'command',
                            func: 'seekTo',
                            args: [0, true]
                        }), '*');
                        iframe.contentWindow.postMessage(JSON.stringify({
                            event: 'command',
                            func: 'playVideo',
                            args: []
                        }), '*');
                    }
                } catch(err) {}
            });

            // Ask YouTube to send state updates
            window.addEventListener('load', function() {
                var iframe = document.getElementById('yt');
                iframe.contentWindow.postMessage(JSON.stringify({
                    event: 'listening',
                    id: 1
                }), '*');
            });
        </script>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube-nocookie.com"))
    }
}

// MARK: - Fullscreen player (with sound + controls)

struct YouTubePlayerView: UIViewRepresentable {
    let videoID: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.backgroundColor = .black
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            html, body { background: #000; width: 100%; height: 100%; overflow: hidden; }
            iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: none; }
        </style>
        </head>
        <body>
        <iframe
            src="https://www.youtube-nocookie.com/embed/\(videoID)?autoplay=1&playsinline=1&rel=0&modestbranding=1&controls=1&fs=0"
            allow="autoplay; encrypted-media"
            allowfullscreen="false">
        </iframe>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube-nocookie.com"))
    }
}

// MARK: - Fullscreen player sheet

struct YouTubePlayerSheet: View {
    let videoID: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            YouTubePlayerView(videoID: videoID)
                .ignoresSafeArea()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.5), radius: 4)
            }
            .padding(.top, 56)
            .padding(.trailing, 16)
        }
    }
}
