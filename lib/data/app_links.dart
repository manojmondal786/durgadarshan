/// Where the app itself is shared from.
abstract final class AppLinks {
  /// The signed Android APK on Google Drive, as a direct download. It is
  /// Drive's own "Download anyway" link, which skips the warning page Drive
  /// shows for executable files.
  static final androidApk = Uri.parse(
    'https://drive.usercontent.google.com/download'
    '?id=1kUf22ostkvRHOeh5GoGncRXUJMrZZTMf&export=download&confirm=t',
  );

  /// The web version, which iPhone users add to their Home Screen.
  static final webApp = Uri.parse(
    'https://manojmondal786.github.io/durgadarshan/',
  );
}
