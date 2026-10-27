import { defineConfig } from 'vitepress'
import { withMermaid } from 'vitepress-plugin-mermaid'

const SITE = 'https://sametcelikbicak.github.io'
const DESCRIPTION = 'A team of AI agents that takes an idea from research to launch — built on opencode, with no framework and no extra dependencies.'

const config = withMermaid(
  defineConfig({
    title: 'OpenCode Team',
    description: DESCRIPTION,
    base: '/opencode-team/',
    lastUpdated: true,
    transformHead({ page, siteConfig }) {
      const path = page.replace(/(^|\/)index\.md$/, '$1').replace(/\.md$/, '')
      const url = `${SITE}${siteConfig.site.base}${path}`
      return [
        ['link', { rel: 'canonical', href: url }],
        ['meta', { property: 'og:url', content: url }],
      ]
    },
    head: [
      ['link', { rel: 'icon', type: 'image/svg+xml', href: '/opencode-team/favicon.svg' }],
      ['link', { rel: 'apple-touch-icon', href: '/opencode-team/favicon.svg' }],
      ['meta', { property: 'og:type', content: 'website' }],
      ['meta', { property: 'og:site_name', content: 'OpenCode Team' }],
      ['meta', { property: 'og:title', content: 'OpenCode Team — AI agent pipeline' }],
      ['meta', { property: 'og:description', content: DESCRIPTION }],
      ['meta', { property: 'og:image', content: `${SITE}/opencode-team/og.jpg` }],
      ['meta', { property: 'og:image:width', content: '1200' }],
      ['meta', { property: 'og:image:height', content: '630' }],
      ['meta', { name: 'twitter:card', content: 'summary_large_image' }],
      ['meta', { name: 'twitter:title', content: 'OpenCode Team — AI agent pipeline' }],
      ['meta', { name: 'twitter:description', content: DESCRIPTION }],
      ['meta', { name: 'twitter:image', content: `${SITE}/opencode-team/og.jpg` }],
      ['meta', { name: 'theme-color', content: '#010314' }],
      ['style', {}, ':root { --vp-nav-logo-height: 48px; }'],
    ],
    themeConfig: {
      logo: '/logo.svg',
      siteTitle: 'OpenCode Team',
      nav: [
        { text: 'Guides', items: [
          { text: 'Getting Started', link: '/install' },
          { text: 'Pipeline', link: '/pipeline' },
          { text: 'Customization', link: '/customization' },
        ]},
        { text: 'Reference', items: [
          { text: 'Agents', link: '/agents' },
          { text: 'Commands', link: '/commands' },
          { text: 'Memory', link: '/memory' },
          { text: 'FAQ', link: '/faq' },
        ]},
      ],
      sidebar: {
        '/': [
          { text: 'Introduction', link: '/' },
          { text: 'Install Guide', link: '/install' },
          {
            text: 'Guides',
            items: [
              { text: 'Pipeline & Gates', link: '/pipeline' },
              { text: 'Customizing the Pipeline', link: '/customization' },
              { text: 'Adding a Role', link: '/customization#adding-a-role' },
            ],
          },
          {
            text: 'Reference',
            items: [
              { text: 'Agents', link: '/agents' },
              { text: 'Commands', link: '/commands' },
              { text: 'FAQ', link: '/faq' },
            ],
          },
          {
            text: 'Memory',
            items: [
              { text: 'Project-Local Memory', link: '/memory' },
            ],
          },
        ],
      },
      search: { provider: 'local' },
      editLink: {
        pattern: 'https://github.com/sametcelikbicak/opencode-team/edit/main/docs/:path',
        text: 'Edit this page on GitHub',
      },
      socialLinks: [
        { icon: 'github', link: 'https://github.com/sametcelikbicak/opencode-team' },
      ],
    },
  }),
)

// The plugin hardcodes `debug` (not installed on mermaid 11) and misses fastdom,
// which the mermaid core imports as CJS. Without prebundling, the dev server
// serves fastdom raw and the browser throws "does not provide an export named default".
config.vite.optimizeDeps.include = [
  ...(config.vite.optimizeDeps.include || []).filter((dep) => dep !== 'debug'),
  'fastdom',
  'fastdom/extensions/fastdom-promised.js',
]

export default config
