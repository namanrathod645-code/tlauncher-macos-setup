# TLauncher macOS setup helper (unofficial)

This small macOS script downloads the **official TLauncher archive** and an **Azul Zulu Java 8 runtime with JavaFX**, checks both against the SHA-256 hashes verified on 2026-09-29, and opens the launcher. It works without Homebrew or administrator access. It does not contain or redistribute TLauncher, Minecraft, or Java binaries.

## Use

1. Download `TLauncher-macOS-setup-v0.1.1.zip` from this repository's **Releases** page and extract it.
2. In Finder, right-click **Run TLauncher.command** and choose **Open**. On later runs, double-click it. Keep the Terminal window open while the launcher runs. Do not disable macOS security settings.
3. First launch downloads about 100 MB. Subsequent launches use the cached files in `~/Library/Application Support/TLauncher-macOS-helper/`.

If you use GitHub's **Download ZIP** for the source instead of the release ZIP, open Terminal in the extracted folder and run `zsh "Run TLauncher.command"`; GitHub's source archive may not preserve the executable flag.

To download and check the files without opening TLauncher:

```sh
zsh "Run TLauncher.command" --prepare-only
```

The helper downloads and caches its own verified Azul Java 8 + JavaFX runtime. It does not use a Java runtime installed by another app.

The helper supports Apple Silicon (`arm64`) and Intel (`x86_64`) Macs. The Apple M2 path was tested locally. The Intel runtime archive and its contents were checked, but launching on an Intel Mac has not been tested.

If the official TLauncher or Azul download changes, the hash check **stops** instead of running unknown files. Open an issue here so the verified hashes can be updated. The helper only addresses downloading and starting the launcher; it cannot fix every Minecraft game download or mod error.

## Sources and rights

- [TLauncher official download](https://tlauncher.org/jar) and [TLauncher Java guidance](https://tlauncher.org/en/install-java.html)
- [Azul Zulu Java downloads](https://www.azul.com/downloads/)

TLauncher, Minecraft, and Azul Zulu belong to their respective owners. This is a community helper and is not affiliated with or endorsed by them. Downloading and using these products remains subject to their own terms. Use a legitimate Minecraft account where required.
