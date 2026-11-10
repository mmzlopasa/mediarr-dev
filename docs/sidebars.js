export default {
  docs: [
    'overview',
    {
      type: 'category', label: 'Install', collapsed: false,
      items: ['install/requirements', 'install/docker-compose', 'install/post-install', 'install/environment-variables', 'install/upgrading', 'install/uninstalling'],
    },
    {
      type: 'category', label: 'Features', collapsed: false,
      items: ['features/library', 'features/cli', 'features/mobile-app', 'features/smart-search', 'features/external-library', 'features/import', 'features/export', 'features/sharing', 'features/editing', 'features/clean-up', 'features/languages', 'features/ai-descriptions', 'features/memories', 'features/tv', 'features/additions', 'features/profile'],
    },
    {
      type: 'category', label: 'Administration', collapsed: false,
      items: ['administration/users', 'administration/sign-in', 'administration/backup', 'administration/storage-template', 'administration/keep', 'administration/reverse-proxy', 'administration/monitoring', 'administration/api-keys'],
    },
    'release-notes',
    'faq',
  ],
};
