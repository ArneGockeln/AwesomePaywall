struct AwesomeWebView: UIViewRepresentable {
        let url: URL

        func makeUIView(context: Context) -> WKWebView {
            return WKWebView()
        }

        func updateUIView(_ webView: WKWebView, context: Context) {
            let request = URLRequest(url: self.url)
            webView.load(request)
        }
    }