# Vex Guild Sync automatic releases

CurseForge project: `1705538`

## One-time setup

1. Create a private or public GitHub repository and upload this folder.
2. In the CurseForge author dashboard, create an API token.
3. In the GitHub repository, open **Settings → Secrets and variables → Actions**.
4. Create a repository secret named `CF_API_TOKEN` and paste the CurseForge token there.
5. Never commit the token to this repository, the addon, or the website.

## Publish a version

Update `## Version` in `VexGuildSync.toc` and `ADDON_VERSION` in
`VexGuildSync.lua`, commit those changes, then create and push a matching tag:

```powershell
git tag -a v1.1.2 -m "Vex Guild Sync 1.1.2"
git push origin v1.1.2
```

The GitHub workflow packages the addon, creates a GitHub release, and uploads
the release to CurseForge project `1705538`. Members using the CurseForge app
can then receive the update through its addon update system.
