import { WebPlugin } from '@capacitor/core';

import type { AbsolutePathResult, DownloadOptions, DownloadProgressCallback, DownloaderPlugin, PathOptions, UnzipOptions } from './definitions';

export class Downloader extends WebPlugin implements DownloaderPlugin {
  async download(options: DownloadOptions, callback: DownloadProgressCallback): Promise<string> {
    const response = await fetch(options.url);

    const reader = response.body?.getReader();
    const contentLength = +(response.headers.get('Content-Length') || 0);
    let receivedLength = 0;
    const chunks = [];
    while (true) {
      const result = await reader?.read();
      if (!result || result.done) {
        break;
      }
      chunks.push(result.value);
      receivedLength += result.value.length;
      callback({
        progress: receivedLength / contentLength
      });
    }

    const chunksAll = new Uint8Array(receivedLength);
    let position = 0;
    for (const chunk of chunks) {
      chunksAll.set(chunk, position);
      position += chunk.length;
    }

    // TODO: 
    // const blob = convertUint8ArrayToBlob(chunksAll);

    return '';
  }
  async absolutePath(options: PathOptions): Promise<AbsolutePathResult> {
    return {
      absolutePath: options.localPath
    };
  }

  async unzip(options: UnzipOptions, callback: DownloadProgressCallback): Promise<string> {
    console.log(options);
    console.log(callback);
    return '';
  }
}
