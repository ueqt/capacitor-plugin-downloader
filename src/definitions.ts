export type CallbackID = string;

export interface DownloadOptions {
  url: string;
  localPath: string;
  headers?: string;
}

export interface DownloadProgressResult {
  progress: number;
}

export interface PathOptions {
  localPath: string;
}

export interface AbsolutePathResult {
  absolutePath: string;
}

export type DownloadProgressCallback = (downloadProgressResult: DownloadProgressResult) => void;

export interface UnzipOptions {
  zipRelativePath: string;
}

export interface UnzipProgressResult {
  progress: number;
}

export type UnzipProgressCallback = (unzipProgressResult: UnzipProgressResult) => void;

export interface DownloaderPlugin {
  download(options: DownloadOptions, callback: DownloadProgressCallback): Promise<CallbackID>;
  absolutePath(options: PathOptions): Promise<AbsolutePathResult>;
  unzip(options: UnzipOptions, callback: UnzipProgressCallback): Promise<CallbackID>;
}
