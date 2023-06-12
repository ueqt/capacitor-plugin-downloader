export type CallbackID = string;

export interface DownloadOptions {
  url: string;
  localPath: string;
}

export interface DownloadProgressResult {
  progress: number;
}

export interface PathOptions {
  localPath: string;
}

export type DownloadProgressCallback = (downloadProgressResult: DownloadProgressResult) => void;

export interface DownloaderPlugin {
  download(options: DownloadOptions, callback: DownloadProgressCallback): Promise<CallbackID>;
  absolutePath(options: PathOptions): Promise<string>;
}
