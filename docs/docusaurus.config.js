const config = {
  title: 'Mediarr',
  tagline: 'Your photos and videos, on your own server',
  favicon: 'favicon.svg?v=2',
  headTags: [
    { tagName: 'link', attributes: { rel: 'icon', href: '/favicon.ico?v=2', sizes: '48x48' } },
    { tagName: 'link', attributes: { rel: 'apple-touch-icon', href: '/apple-touch-icon.png' } },
  ],
  url: 'https://docs.mediarr.app',
  baseUrl: '/',
  trailingSlash: false,
  onBrokenLinks: 'throw',
  markdown: { hooks: { onBrokenMarkdownLinks: 'throw' } },
  i18n: { defaultLocale: 'en', locales: ['en'] },
  themes: [
    [
      '@easyops-cn/docusaurus-search-local',
      { hashed: true, docsRouteBasePath: '/', indexBlog: false, indexPages: false },
    ],
  ],
  presets: [
    [
      'classic',
      {
        docs: { routeBasePath: '/', sidebarPath: './sidebars.js' },
        blog: false,
        theme: { customCss: './src/css/custom.css' },
      },
    ],
  ],
  themeConfig: {
    colorMode: { defaultMode: 'dark', respectPrefersColorScheme: true },
    navbar: {
      logo: { alt: 'Mediarr', src: 'img/logo-full.svg', srcDark: 'img/logo-full-dark.svg', height: 26 },
      items: [
        { to: '/install/docker-compose', label: 'Install', position: 'left' },
        { to: '/features/mobile-app', label: 'Features', position: 'left' },
        { to: '/administration/users', label: 'Administration', position: 'left' },
        { href: 'https://mediarr.app', label: 'Website', position: 'right' },
        { href: 'https://demo.mediarr.app', label: 'Demo', position: 'right' },
      ],
    },
    footer: { copyright: `Copyright © ${new Date().getFullYear()} Mediarr` },
    prism: { additionalLanguages: ['bash', 'nginx', 'yaml'] },
  },
};
export default config;
