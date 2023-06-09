import { registerPlugin } from '@capacitor/core';

import type { DownloaderPlugin as PluginDefinition } from './definitions';
import { Downloader } from './web';

const DownloaderPlugin = registerPlugin<PluginDefinition>('DownloaderPlugin', {
  web: () => new Downloader(),
});

export * from './definitions';
export { DownloaderPlugin };
