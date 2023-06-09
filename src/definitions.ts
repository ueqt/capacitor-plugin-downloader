export type CallbackID = string;

export interface DownloadOptions {
  url: string;
  localPath: string;
  fileName: string;
}

export interface DownloadProgressResult {
  progress: number;
}

export type DownloadProgressCallback = (downloadProgressResult: DownloadProgressResult) => void;

export interface DownloaderPlugin {
  download(options: DownloadOptions, callback: DownloadProgressCallback): Promise<CallbackID>;
}
