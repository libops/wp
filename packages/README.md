# Local WordPress packages

Keep source for site-owned plugins and themes in one directory per package
under this folder. Composer copies these packages into the generated `web/app`
installer destinations; do not edit or commit those generated destinations.

A minimal plugin package at `packages/example-plugin/composer.json` looks like:

```json
{
  "name": "example/example-plugin",
  "description": "Site-owned WordPress plugin.",
  "type": "wordpress-plugin",
  "version": "dev-main"
}
```

Use `wordpress-theme` for a theme or `wordpress-muplugin` for a must-use
plugin. Put the package's PHP, CSS, and other source files beside its
`composer.json`, then add it to the root project and refresh the lockfile:

```bash
sitectl wp composer require example/example-plugin:@dev
```

The root `packages/*` path repository sets `symlink: false`. Local installs and
production image builds therefore copy the same checked-in source into the
appropriate installer destination without depending on a host-installed tree.
Package-local `.git`, `vendor`, and `node_modules` directories are ignored;
commit any intentionally built distribution assets that the package requires.
