import receive_sharing_intent

/// The system share sheet's entry into Easy Plate. The plugin's controller
/// copies what was shared into the app group and opens the app on it; the
/// ingestion screen takes it from there (see ShareIntentService).
class ShareViewController: RSIShareViewController {
    override func shouldAutoRedirect() -> Bool {
        return true
    }
}
